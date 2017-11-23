require 'net/http'
require 'uri'
require 'logger'

class BlockedResource < StandardError; end;

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
      update_remove_host: '/update_remove_host',
      check_resource_available: '/check_resource_available'
    })

    @@config[:host_server] = 'http://localhost:3000' unless @@config[:host_server]
  end

  def self.config
    @@config
  end

  def self.reserve_resource(resource)
    if ReservedResources.any?(resource)
      raise BlockedResource
    else
      Hosts.all.each do |host|
        response = self.post(host + @@config[:check_resource_available], { resource: resource.to_json })

        if JSON.parse(response.body)['resource_reserved']
          raise BlockedResource
        end
      end

      ReservedResources.add(resource)
    end
  end

  def self.free_resource(resource)
    ReservedResources.remove(resource)
  end

  def self.connect_to_server
    response = post(@@config[:host_server] + @@config[:register_first_new_host], { this_host: @@config[:this_host] })
    JSON.parse(response.body)['existing_hosts']
  end

  def self.setup
    connect_to_first_server

    Thread.new do
      while true do
        ReservedResources.all_with_created_at.each do |resource|

          # p "#{resource['created_at'].to_time} #{Time.at(DateTime.now.to_i - 60 * 1)}"
          if resource['created_at'].to_time <= Time.at(DateTime.now.to_i - 60 * 1)
            p "Removing resource #{resource.inspect}"
            ReservedResources.remove(resource['resource'])
          end
        end

        sleep(3)
      end
    end
  end

  def self.connect_to_first_server
    Hosts.create([])
    ReservedResources.create([])
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
    elsif env['REQUEST_METHOD'] == 'POST' && env['PATH_INFO'] == '/check_resource_available'
      params = JSON.parse(env['rack.input'].gets)
      resource = JSON.parse(params['resource'])
      [200, {}, [{ resource_reserved: ReservedResources.any?(resource) }.to_json]]
    else
      # params = Rack::Request.new(env).params

      # if ReservedResources.any? params
      #   [400, {}, ['Resource locked']]
      # else
        @app.call(env)
      # end
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

class FileManagment
  def self.create(itens = [])
    File.open(file, 'w') do |f|
      itens.each do |iten|
        f.write(iten)
        f.write("\n")
      end
    end
  end

  def self.add(iten)
    return if all.include?(iten)

    File.open(file, 'a') do |f|
      f.write(iten)
      f.write("\n")
    end
  end

  def self.remove(item_to_remove)
    itens = all
    itens.delete_if { |item| item == item_to_remove }
    self.create(itens)
  end

  def self.all
    File.open(file, 'r') do |f|
      f.map { |item|; item.gsub(/\n/, '') }
    end
  end
end

class Hosts < FileManagment
  def self.file
    'hosts.csv'
  end
end

class ReservedResources < FileManagment
  def self.file
    'reserved_resources.csv'
  end

  def self.add(resource)
    super({ created_at: DateTime.now, resource: resource }.to_json)
  end

  def self.all
    super.map { |record| JSON.parse(record)['resource'] }
  end

  def self.all_with_created_at
    File.open(file, 'r') do |f|
      f.map { |item|; JSON.parse(item.gsub(/\n/, '')) }
    end
  end

  def self.remove(resource)
    super(resource.stringify_keys) if resource
  end

  def self.create(resources = [])
    super(resources.map { |resource| { created_at: DateTime.now, resource: resource }.to_json })
  end

  def self.any?(resource)
    all.any? do |r|
      r == resource.stringify_keys
    end
  end
end
