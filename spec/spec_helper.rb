require 'bundler/setup'
Bundler.setup

require 'cthulhu' # and any other gems you need
require 'support/bunny_mock'

RSpec.configure do |config|
  ENV['RABBIT_USER'] = 'user'
  ENV['RABBIT_PW'] = 'pass'
  ENV['APP_ENV'] = 'test'
  ENV['RABBIT_HOST'] = 'rabbitmq.dummy'

end
