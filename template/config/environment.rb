require 'rubygems'
require 'bundler/setup'
require 'logger'

unless ENV['CTHULHU_ENV']
  puts "Environment variable CTHULHU_ENV is not set. Assuming environment 'development'."
  ENV['CTHULHU_ENV'] = 'development'
end

Bundler.require(:default) # requires all gems outside groups
Bundler.require(ENV['CTHULHU_ENV'])

Dir["./config/config.rb"].each {|file| require file }
Dir["./config/environments/#{ENV['CTHULHU_ENV']}.rb"].each {|file| require file }
Cthulhu.require_all "./config/initializers/**/*.rb"
Cthulhu.require_all "./app/**/*.rb"
Dir["./config/routes.rb"].each {|file| require file }
