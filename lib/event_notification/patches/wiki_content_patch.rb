module EventNotification
  module Patches
    module WikiContentPatch

      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
          alias_method_chain :notified_users, :events
        end
      end

      module InstanceMethods
        def notified_users_with_events
          if Setting.plugin_event_notifications["enable_event_notifications"] == "on"
            notified = project.notified_users(self)
            notified.reject! {|user| !visible?(user)}
            notified.collect(&:mail)
          else
            recipients_without_events
          end
        end
      end
    end
  end
end

unless WikiContent.included_modules.include? EventNotification::Patches::WikiContentPatch
  WikiContent.send(:include, EventNotification::Patches::WikiContentPatch)
end
