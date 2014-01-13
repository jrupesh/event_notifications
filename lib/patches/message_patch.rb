module Patches
  module MessagePatch

    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable
        alias_method_chain :recipients, :events
      end
    end

    module InstanceMethods
      def recipients_with_events
        notified = Setting.plugin_event_notifications["enable_event_notifications"] == "on" ? project.notified_users(self) :
             project.notified_users

        notified.reject! {|user| !visible?(user)}
        notified.collect(&:mail)
      end
    end
  end
end

Message.send(:include, Patches::MessagePatch)
