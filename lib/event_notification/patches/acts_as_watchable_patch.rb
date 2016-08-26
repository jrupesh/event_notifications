module EventNotification
  module Patches
    module ActsAsWatchablePatch

      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
          alias_method_chain :notified_watchers, :events
        end
      end

      module InstanceMethods
        def notified_watchers_with_events
          return [] if User.current.ghost? || User.get_notification == false
          if Setting.plugin_event_notifications["enable_event_notifications"] == "on"
            notified = watcher_users.active.to_a
            notified.reject! {|user| user.mail.blank? || user.mail_notification == 'none'}
            if respond_to?(:visible?)
              notified.reject! {|user| !visible?(user)} unless respond_to?(:project) && project.notify_non_member
            end
            notified            
          else
            notified_watchers_without_events
          end
        end
      end
    end
  end
end

unless Redmine::Acts::Watchable::InstanceMethods.included_modules.include? EventNotification::Patches::ActsAsWatchablePatch
  Redmine::Acts::Watchable::InstanceMethods.send(:include, EventNotification::Patches::ActsAsWatchablePatch)
end
