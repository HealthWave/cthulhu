require 'rubygems'
require 'bundler/setup'
require 'logger'
Bundler.require(:default) # requires all gems outside groups
Bundler.require(ENV['APP_ENV'])

Dir["./lib/cthulhu.rb"].each {|file| require file }
Dir["./lib/helpers/*.rb"].each {|file| require file }
Dir["./config/routes.rb"].each {|file| require file }
Dir["./config/initializers/*.rb"].each {|file| require file }
Dir["./app/handlers/*.rb"].each {|file| require file }
Dir["./app/models/*.rb"].each {|file| require file }


# Only change this line if you know what you are doing. This could seriously
# break things.
Cthulhu::Application.name = '__APP_NAME__'
Cthulhu::Application.queue_name = Cthulhu::Application.name + '.__QUEUE_UUID__'

# Cthulhu will write to logs/app_name.log by default.
# If you want a custom logger, change it here:
Cthulhu::Application.logger = Logger.new("logs/#{Cthulhu::Application.name}.log")


Cthulhu::Application.start
