module Patches
  module IssuePatch

    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable

        before_save :set_new_issue_record
        alias_method_chain :notified_users, :events
      end
    end

    module InstanceMethods
      def set_new_issue_record
        @set_issue_record = new_record? ? 1 : 0
      end

      def is_issue_new_record?
        @set_issue_record ||= 0
      end

      def notified_users_with_events
        if Setting.plugin_event_notifications["enable_event_notifications"] == "on"
          notified = []
          # Author and assignee are always notified unless they have been
          # locked or don't want to be notified
          notified << author if author
          if assigned_to
            notified += (assigned_to.is_a?(Group) ? assigned_to.users : [assigned_to])
          end
          if assigned_to_was
            notified += (assigned_to_was.is_a?(Group) ? assigned_to_was.users : [assigned_to_was])
          end
          notified = notified.select {|u| u.active? && u.notify_about?(self)}
          notified +=  project.notified_users_with_events(self)
          notified.uniq!
          # Remove users that can not view the issue
          notified.reject! {|user| !visible?(user)}
          notified
        else
          notified_users_without_events
        end
      end
    end
  end
end

Issue.send(:include, Patches::IssuePatch)