module Patches
  module JournalPatch

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
          logger.debug("Notified Users : Select users.")

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
