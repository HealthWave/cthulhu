require 'bunny'
require 'json'
require 'logger'

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
  def self.route(subject:, event: )
    @@routes ||= {}
    @@routes[subject] = event
  end

  def self.channel
    return @@channel if @@channel
    conn = ::Bunny.new(user: ENV['RABBIT_USER'], pass: ENV['RABBIT_PW'], host: ENV['RABBIT_HOST'], vhost: "/")
    conn.start
    @@channel = conn.create_channel
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
