require 'ostruct'

module Cthulhu
  class Application

    def self.logger
      Cthulhu.logger
    end

    def self.start(block: true)
      return if Cthulhu.env == 'test' && Cthulhu.run_on_test_environment == false
      return if ENV['CONSOLE']
      puts "Starting #{Cthulhu.app_name}, enviroment #{Cthulhu.env}."
      puts "Cthulhu #{Cthulhu.version} loaded. Press CTRL+C to QUIT."
      # Start inbox queue
      Cthulhu::Queue.new(:inbox, block: block).start

    end

    def self.call_global_route(message)
      klass = Object.const_get Cthulhu.global_route[:to]
      klass.new(message).handle_action(Cthulhu.global_route[:action])
    rescue NameError => e
      raise MissingGlobalRouteError.new("#{Cthulhu.global_route[:to]} class is missing or not defined, global routes must be defined.")
    end
  end
end
