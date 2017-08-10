class MyTest
  attr_accessor :options

  def initialize app
    @app = app
  end

  def self.configure(options = {})
    puts 'configuring ------'
    @options = options
  end

  def self.options
    @options
  end

  def call(env)
    puts "------#{options.inspect}"
    if env['REQUEST_METHOD'] == 'POST' && env['PATH_INFO'] == '/set_new_host'
      puts "Setting new host----------------------"
      [201, {}, [{ msg: 'adsf' }.to_json]]
    else
      response = @app.call(env)
      if self.class.options[:foo] == :bar
        binding.pry
      end
      response
    end
  end
end
