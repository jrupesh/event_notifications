module Patches
  module MessagePatch

    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable
      end
    end

    module InstanceMethods
      def recipients
        notified = project.notified_users(self)
        notified.reject! {|user| !visible?(user)}
        notified.collect(&:mail)
      end
    end
  end
end

Message.send(:include, Patches::MessagePatch)
