require 'bunny'
require 'json'
require 'logger'
require 'httparty'
require 'cthulhu/helpers/mattr_accessors'
require 'cthulhu/helpers/cattr_accessors'
require 'byebug'
# Create a queue where the messages will be lined up to be delivered to an exchange
CTHULHU_QUEUE = Queue.new

module Cthulhu
  mattr_accessor :routes, :routes_exp, :channel, :global_route, :logger, :organization,
                 :app_name, :inbox_exchange, :inbox_exchange_name,
                 :organization_inbox_exchange, :organization_inbox_exchange_name,
                 :fqan, :rails, :env, :peers,
                 :rabbit_user, :rabbit_pw, :rabbit_host, :rabbit_port, :rabbit_vhost, :rabbit_ssl, :rabbit_api_url

  def self.configure &block
    # set rails to false by default.
    # To enable it, set it to true on Cthulhu.configure
    rails = false
    if block_given?
      instance_eval &block
      # byebug
      self.organization_inbox_exchange_name = organization
      self.fqan = "#{organization_inbox_exchange_name}.#{app_name}"
      self.inbox_exchange_name = fqan
      self.env = ENV['CTHULHU_ENV']
      self.rabbit_host ||= '127.0.0.1'
      self.rabbit_vhost ||= '/'
      self.rabbit_port ||= 5672
      self.rabbit_ssl ||= nil
      if rails? # RAILS is defined on config/initializers cthulhu.rb configure block on a rails app
        self.logger = Rails.logger
      else
        raise "Invalid logger. Expected Logger but got #{logger.class.name}" unless logger.instance_of?(Logger)
      end
    else
      raise "Configuration requires a block."
    end
  end

  def self.rails?
    rails
  end

  def self.delete_routes
    routes = nil
    global_route = nil
  end

  def self.routes &block
    if block_given?
      instance_eval &block
      self.routes_exp ||= {}
      @@routes.each do |r,_|
        # Here I have to map the wildcards from rabbitmq to regular expressions, so I can then match with incoming routing keys.
        # * is replaced by the regexp for any single word, and # is replaced by zero or many words
        case r
        when '#', '*'
          self.routes_exp[r] = Regexp.new '\A[\w\.]*\z'
        # when '*'
        #   self.routes_exp[r] = Regexp.new '\A\w+\z'
        else
          self.routes_exp[r] = Regexp.new '\\A' + r.gsub(/(\.#).*/, "[\\w\\.]*").gsub(/(?<=[\w\*])\.(?=[\w\*])/,"\\.").gsub(/\A\*/,'\\w+').gsub('.*', "\\.\\w+") + '\\z'
        end
      end
    else
      @@routes
    end
  end

  def self.route(routing_key, to: )
    self.routes ||= {}
    klass_name, method = to.split('#')
    self.routes[routing_key] = [Object.const_get(klass_name), method]
  end

  def self.channel
    return @@channel if @@channel
    conn = ::Bunny.new(user: rabbit_user, pass: rabbit_pw, host: rabbit_host, vhost: rabbit_vhost, port: rabbit_port)
    conn.start
    self.channel = conn.create_channel
  end
  def self.organization_inbox_exchange
    return @@organization_inbox_exchange if @@organization_inbox_exchange
    self.organization_inbox_exchange = self.channel.fanout(self.organization_inbox_exchange_name, auto_delete: false, durable: true)
  end

  def self.inbox_exchange
    return @@inbox_exchange if @@inbox_exchange
    # this will create the organization_inbox_exchange if it doesn't exist
    self.inbox_exchange = Cthulhu::Inbox.create(parent: self.organization_inbox_exchange)
  end

  class MissingGlobalRouteError < NameError
  end
end


########################
####### REQUIRES #######
########################
require 'cthulhu/version'
require 'cthulhu/helpers/blank_helper'
require 'cthulhu/main'
require 'cthulhu/handler'
require 'cthulhu/message'
require 'cthulhu/pool'
require 'cthulhu/notifier'
require 'cthulhu/inbox'
require 'cthulhu/queue'
# Railtie
require 'cthulhu/railtie' if Cthulhu.rails

# require models and handlers folder
Dir["./app/models/**/*.rb"].each {|file| require file }
Dir["./app/handlers/**/*.rb"].each {|file| require file }
