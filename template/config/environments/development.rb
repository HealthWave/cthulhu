Cthulhu.configure do |config|

  # Override log from config.rb
  # config.logger = Logger.new(STDOUT)

  # Override RabbitMQ connectio info. Note some values have defaults,
  # and others you have to set yourself
  # You can override this per environment
  # config.rabbit_user = ENV['RABBIT_USER']
  # config.rabbit_pw = ENV['RABBIT_PW']
  # config.rabbit_host = ENV['RABBIT_HOST']
  # config.rabbit_api_url = ENV['RABBIT_HOST']
  # default values
  # config.rabbit_vhost = '/'
  # config.rabbit_port = 5672

end
