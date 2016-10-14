require 'rubygems'
require 'bundler/setup'
require 'logger'

raise "Environment variable CTHULHU_ENV is not set. Common values are 'development', 'staging' or 'production'." unless ENV['CTHULHU_ENV']
CTHULHU_ENV = ENV['CTHULHU_ENV']

Bundler.require(:default) # requires all gems outside groups
Bundler.require(CTHULHU_ENV)

Dir["./config/environments/#{CTHULHU_ENV}.rb"].each {|file| require file }
Dir["./config/config.rb"].each {|file| require file }
Dir["./config/routes.rb"].each {|file| require file }
Dir["./config/initializers/**/*.rb"].each {|file| require file }
