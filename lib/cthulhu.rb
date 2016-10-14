require 'bunny'
require 'json'
require 'logger'
require 'cthulhu/helpers/mattr_accessors'
require 'cthulhu/helpers/cattr_accessors'

CTHULHU_QUEUE = Queue.new

module Cthulhu
  mattr_accessor :routes, :channel, :global_route, :logger, :organization,
                 :app_name, :inbox_exchange, :parent_inbox_exchange, :fqan, :rails

  def configure &block
    if block_given?
      instance_eval &block
      if rails # RAILS is defined on config/initializers cthulhu.rb configure block on a rails app
        logger = Rails.logger
      else
        raise "Invalid logger. Expected Logger but got #{logger.class.name}" unless logger.instance_of?(Logger)
      end
    else
      raise "Configuration requires a block."
    end
  end

  def self.delete_routes
    routes = nil
    global_route = nil
  end

  def self.routes &block
    if block_given?
      instance_eval &block
    end
    routes
  end
  # Removed in favour of the new syntax
  # def self.route(subject:, to: )
  #   routes ||= {}
  #   routes[subject] = to
  # end

  def self.subject(subject, &block)
    if block_given?
      action_name, value = instance_eval &block
    else
      raise "Block missing declaring subject."
    end
    routes ||= {}
    key = "#{subject}.#{action_name}"
    routes[key] = value
  end

  def self.route_action(action_name, to: )
    [action_name, to]
  end

  def self.catch_all(to:, action:)
    global_route = {to: to, action: action}
  end

  def self.channel
    return channel if channel
    conn = ::Bunny.new(user: ENV['RABBIT_USER'], pass: ENV['RABBIT_PW'], host: ENV['RABBIT_HOST'], vhost: "/")
    conn.start
    channel = conn.create_channel
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
require 'cthulhu/main'
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

# require handlers folder
Dir["./app/handlers/**/*.rb"].each {|file| require file }
