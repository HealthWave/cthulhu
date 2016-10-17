require 'bunny'
require 'json'
require 'logger'
require 'cthulhu/helpers/mattr_accessors'
require 'cthulhu/helpers/cattr_accessors'

# Create a queue where the messages will be lined up to be delivered to an exchange
CTHULHU_QUEUE = Queue.new

module Cthulhu
  mattr_accessor :routes, :channel, :global_route, :logger, :organization,
                 :app_name, :inbox_exchange,:inbox_exchange_name,
                 :organization_inbox_exchange, :organization_inbox_exchange_name, :fqan, :rails

  def configure &block
    if block_given?
      instance_eval &block
      organization_inbox_exchange_name = organization
      fqan = "#{organization_inbox_exchange_name}.#{app_name}"
      inbox_exchange_name = fqan
      if rails? # RAILS is defined on config/initializers cthulhu.rb configure block on a rails app
        logger = Rails.logger
      else
        raise "Invalid logger. Expected Logger but got #{logger.class.name}" unless logger.instance_of?(Logger)
      end
    else
      raise "Configuration requires a block."
    end
  end

  def rails?
    rails || false
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

  def self.route(topic, to: )
    routes ||= {}
    routes[topic] = to
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
  def self.organization_inbox_exchange
    return organization_inbox_exchange if organization_inbox_exchange
    self.organization_inbox_exchange = self.channel.direct(self.organization_inbox_exchange_name, auto_delete: false)
  end

  def self.inbox_exchange
    return inbox_exchange if inbox_exchange
    self.inbox_exchange = Cthulhu::Inbox.create(parent: Cthulhu.organization_inbox_exchange)
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
require 'cthulhu/railtie' if Cthulhu.rails
# Alias
C = Cthulhu

# require models and handlers folder
Dir["./app/models/**/*.rb"].each {|file| require file }
Dir["./app/handlers/**/*.rb"].each {|file| require file }
