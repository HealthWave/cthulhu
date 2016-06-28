require 'rubygems'
require 'bundler/setup'
require 'logger'

ENV['CTHULHU_ENV'] = Object.const_defined?("Rails") ? Rails.env : ENV['CTHULHU_ENV']

Bundler.require(:default) # requires all gems outside groups
Bundler.require(ENV['CTHULHU_ENV'])

Dir["./lib/cthulhu.rb"].each {|file| require file }
Dir["./lib/helpers/*.rb"].each {|file| require file }
Dir["./config/routes.rb"].each {|file| require file }
Dir["./config/initializers/*.rb"].each {|file| require file }
Dir["./app/handlers/*.rb"].each {|file| require file }
Dir["./app/models/*.rb"].each {|file| require file }

# Apps we are allowed to send RPC calls to
RPC_APPS = []

# Only change this line if you know what you are doing. This could seriously
# break things.
Cthulhu::Application.name = '__APP_NAME__'
Cthulhu::Application.queue_name = Cthulhu::Application.name
Cthulhu::Application.dry_run = false

# Cthulhu will write to logs/app_name.log by default.
# If you want a custom logger, change it here:
case ENV['CTHULHU_ENV']
when "development"
  Cthulhu::Application.logger = Logger.new(STDOUT)
else
  Cthulhu::Application.logger = Logger.new("logs/#{Cthulhu::Application.name}.log")
end

Cthulhu::Application.start
