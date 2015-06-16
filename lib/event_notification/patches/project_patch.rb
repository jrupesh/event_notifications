module EventNotification
  module Patches
    module ProjectPatch

      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
          alias_method_chain :notified_users, :events
        end
      end

      module InstanceMethods
        def notified_users_with_events(object=nil)
          return [] if User.current.ghost? || User.get_notification == false
          if !object.nil? && Setting.plugin_event_notifications["enable_event_notifications"] == "on"
            logger.debug("Event Notifications: Notified Users : Select project users activated the event.")

            members.includes(:principal).select {|m| m.principal.present? && ( (m.mail_notification? && m.principal.notify_about_with_event?(object) ) ||
              m.principal.mail_notification == 'all')}.collect {|m| m.principal}
          else
            # members.select {|m| m.principal.present? && (m.mail_notification? || m.principal.mail_notification == 'all')}.collect {|m| m.principal}
            notified_users_without_events
          end
        end
      end
    end
  end
end

unless Project.included_modules.include? EventNotification::Patches::ProjectPatch
  Project.send(:include, EventNotification::Patches::ProjectPatch)
end
