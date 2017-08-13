puts 'Configuring remote control'
port = Rack::Server.new.options[:Port]
port = 3000 if port == 9292

RemoteControl.configure do |config|
  config[:first_server] = ENV['FIRST_SERVER'] == 'true'
  config[:this_host] = 'http://localhost:' + port.to_s
  config[:host_server] = 'http://localhost:3000'
end

RemoteControl.setup

