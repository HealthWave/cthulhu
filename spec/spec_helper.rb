require 'bundler/setup'
require 'byebug'
Bundler.setup

require 'cthulhu' # and any other gems you need

# Require all support files
Dir[File.dirname(__FILE__) + '/support/*.rb'].each {|file| require file }


RSpec.configure do |config|
  ENV['RABBIT_USER'] = 'user'
  ENV['RABBIT_PW'] = 'pass'
  ENV['CTHULHU_ENV'] = 'test'
  ENV['RABBIT_HOST'] = 'rabbitmq.dummy'

end
