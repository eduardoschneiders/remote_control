require 'net/http'
require 'uri'
require 'logger'

class RemoteControl
  attr_accessor :config
  @@config = {}
  @@logger = Logger.new(STDOUT)

  def initialize app
    @app = app
    @@is_blocking = false
  end

  def self.configure
    yield @@config

    @@config.merge!({
      register_first_new_host: '/register_first_new_host',
      update_new_host: '/update_new_host',
      update_remove_host: '/update_remove_host'
    })

    @@config[:host_server] = 'http://localhost:3000' unless @@config[:host_server]
  end

  def self.config
    @@config
  end

  def self.set_as_blocking(resource)
   @@is_blocking = true
   @@resource = resource
  end

  def self.connect_to_server
    response = post(@@config[:host_server] + @@config[:register_first_new_host], { this_host: @@config[:this_host] })
    JSON.parse(response.body)['existing_hosts']
  end

  def self.connect_to_first_server
    Hosts.create([])
    unless @@config[:first_server]
      begin
        existing_hosts = connect_to_server
        Hosts.create(existing_hosts)
      rescue
        raise 'Error to connect to first server'
      end
    end
  end

  def call(env)
    if env['REQUEST_METHOD'] == 'POST' && env['PATH_INFO'] == '/register_first_new_host'
      puts "Registering first new host ----------------------"
      data = JSON.parse(env['rack.input'].gets)
      existing_hosts = Hosts.all
      existing_hosts.delete_if { |h| h == data['this_host'] }

      Hosts.add(data['this_host'])

      alive_hosts = existing_hosts.clone
      existing_hosts.each do |host|
        begin
          response = self.class.post(host + @@config[:update_new_host], { this_host: data['this_host'] })
        rescue
          @@logger.warn("Failed to connect to server #{host}")
          Hosts.remove(host)
          alive_hosts.delete_if { |h| h == host}
          alive_hosts.each do |h|
            response = self.class.post(h + @@config[:update_remove_host], { this_host: host })
          end
        end
      end

      [201, {}, [{ existing_hosts: alive_hosts << @@config[:this_host] }.to_json]]
    elsif env['REQUEST_METHOD'] == 'POST' && env['PATH_INFO'] == '/update_new_host'
      data = JSON.parse(env['rack.input'].gets)
      Hosts.add(data['this_host'])
      [201, {}, []]
    elsif env['REQUEST_METHOD'] == 'POST' && env['PATH_INFO'] == '/update_remove_host'
      data = JSON.parse(env['rack.input'].gets)
      Hosts.remove(data['this_host'])
      [201, {}, []]
    else
      response = @app.call(env)
      # if self.class.options[:foo] == :bar
      if @@is_blocking
      end
      response
    end
  end

  def self.post(url, data)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri, {'Content-Type': 'text/json'})
    request.body = data.to_json
    http.request(request)
  end
end

class Hosts
  def self.create(hosts = [])
    File.open('hosts.csv', 'w') { |f| hosts.each { |h| f.write(h + "\n") }}
  end

  def self.add(host)
    return if all.include?(host)

    File.open('hosts.csv', 'a') do |f|
      f.write(host + "\n")
    end
  end

  def self.remove(host)
    hosts = all
    hosts.delete_if { |h| h == host}
    self.create(hosts)
  end

  def self.all
    File.open('hosts.csv', 'r') do |f|
      f.map { |h|; h.gsub(/\n/, '') }
    end
  end
end
