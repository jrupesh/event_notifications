module Patches
  module JournalPatch

    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      if Redmine::VERSION.to_s >= "2.4"
        base.class_eval do
          unloadable
          alias_method_chain :notified_users, :events
        end
      else
        base.class_eval do
          unloadable
          alias_method_chain :recipients, :events
        end
      end
    end

    module InstanceMethods
      def recipients_with_events
        if Setting.plugin_event_notifications["enable_event_notifications"] == "on"
          notified_users_with_events.map(&:mail)
        else
          recipients_without_events
        end
      end

      def notified_users_with_events
        if Setting.plugin_event_notifications["enable_event_notifications"] == "on"
          notified = journalized.notified_users
          notified += journalized.project.notified_users(self) 
          notified = notified.select {|u| u.active?}          
          notified.uniq!
          if private_notes?
            notified = notified.select {|user| user.allowed_to?(:view_private_notes, journalized.project)}
          end
          notified
        else
          notified_users_without_events
        end
      end
    end
  end
end

Journal.send(:include, Patches::JournalPatch)
