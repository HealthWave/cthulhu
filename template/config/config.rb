Cthulhu.configure do |config|
  # The organization. Example: 'com.example'
  config.organization = '__ORGANIZATION__'
  # app name.
  config.app_name = '__APP_NAME__'
  # set this to true if rails is this is running inside rails
  # config.rails = false

  # RabbitMQ connectio info. Note some values have defaults,
  # and others you have to set yourself
  config.rabbit_user = ENV['RABBIT_USER']
  config.rabbit_pw = ENV['RABBIT_PW']
  config.rabbit_host = ENV['RABBIT_HOST']
  config.rabbit_api_url = ENV['RABBIT_HOST']
  # default values
  # config.rabbit_vhost = '/'
  # config.rabbit_port = 5672
  # config.rabbit_ssl = false

end
