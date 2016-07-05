require 'bunny'
require 'json'
require 'logger'

CTHULHU_QUEUE=Queue.new

module Cthulhu
  @@routes = nil
  @@channel = nil

  def self.delete_routes
    @@routes = nil
  end

  def self.routes &block
    if block_given?
      instance_eval &block
    end
    @@routes
  end
  def self.route(subject:, to: )
    @@routes ||= {}
    @@routes[subject] = to
  end

  def self.channel
    return @@channel if @@channel
    conn = ::Bunny.new(user: ENV['RABBIT_USER'], pass: ENV['RABBIT_PW'], host: ENV['RABBIT_HOST'], vhost: "/")
    conn.start
    @@channel = conn.create_channel
  end

  def self.publish(message)
    if Cthulhu::Pool.thread.nil? || !Cthulhu::Pool.thread.alive?
      Cthulhu::Pool.start
    end
    CTHULHU_QUEUE << message
  end
end


########################
####### REQUIRES #######
########################
require 'cthulhu/helpers/blank_helper'
require 'cthulhu/application'
require 'cthulhu/subscriber'
require 'cthulhu/handler'
require 'cthulhu/message'
require 'cthulhu/pool'
require 'cthulhu/rpc'
require 'cthulhu/notifier'
# Alias
C = Cthulhu
# RAILS SETUP
if Object.const_defined?("Rails")

  require 'cthulhu/railtie'
  ENV['CTHULHU_ENV'] = Rails.env

  Cthulhu::Application.name ||= Rails.application.class.parent_name
  Cthulhu::Application.queue_name ||= Cthulhu::Application.name

  case Rails.env
  when "development", "test"
    lgr = Cthulhu::Application.logger = Logger.new(STDOUT)
  else
    lgr = Cthulhu::Application.logger = Logger.new("log/#{Cthulhu::Application.name}.log")
  end

  Cthulhu::Application.logger ||= (Rails.logger || lgr)

end
