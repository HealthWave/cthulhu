module Cthulhu
  module Notifier
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def cthulhu_notify(on: [])
        include Cthulhu::Notifier::InstanceMethods
        if on.any?
          on.each do |o|
            after_destroy { |model| model.cthulhu_publish(action: "destroyed") } if o == :destroy
            after_save { |model| model.cthulhu_publish(action: "created") } if o == :create
            after_save { |model| model.cthulhu_publish(action: "updated") } if o == :update
          end
        else
          after_destroy { |model| model.cthulhu_publish(action: "destroyed") }
          after_save { |model| model.cthulhu_publish(action: "created") }
          after_save { |model| model.cthulhu_publish(action: "updated") }
        end
      end
    end

    module InstanceMethods
      def cthulhu_publish(action:)
        Cthulhu.publish(subject: self.class.name, action: action, payload: self.attributes )
      end
    end
  end
end
