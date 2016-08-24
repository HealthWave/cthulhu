require 'cthulhu'
require 'rails'

module Cthulhu
  class Railtie < ::Rails::Railtie

    initializer "cthulhu_notify.active_record" do |app|
      ActiveSupport.on_load :active_record do
        include Cthulhu::Notifier
      end
    end

  end
end
