require 'bunny'
require 'json'
require 'logger'

CTHULHU_QUEUE=Queue.new

module Cthulhu
  @@routes = nil
  @@channel = nil
  @@global_route = nil

  def self.delete_routes
    @@routes = nil
    @@global_route = nil
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

  def self.catch_all(to:, action:)
    @@global_route = {to: to, action: action}
  end

  def self.global_route
    @@global_route
  end

  def self.channel
    return @@channel if @@channel
    conn = ::Bunny.new(user: ENV['RABBIT_USER'], pass: ENV['RABBIT_PW'], host: ENV['RABBIT_HOST'], vhost: "/")
    conn.start
    @@channel = conn.create_channel
  end
  def self.publish_now(message)
    if Object.const_defined?("Rails")
      Cthulhu::Application.name = Rails.application.class.parent_name
    end
    Cthulhu::Message.broadcast(message)
  end
  def self.publish(message)
    if Cthulhu::Pool.thread.nil? || !Cthulhu::Pool.thread.alive?
      Cthulhu::Pool.start
    end
    CTHULHU_QUEUE << message
  end

  class MissingGlobalRouteError < NameError
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
# Railtie
require 'cthulhu/railtie' if Object.const_defined?("Rails")
# Alias
C = Cthulhu
