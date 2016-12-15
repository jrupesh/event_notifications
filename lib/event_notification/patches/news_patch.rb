module EventNotification
  module Patches
    module NewsPatch

      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
          alias_method_chain :notified_users, :events
        end
      end

      module InstanceMethods
        def notified_users_with_events
          return [] if User.current.ghost? || User.current.admin_ghost? || User.get_notification == false
          if Setting.plugin_event_notifications["enable_event_notifications"] == "on"
            notified = project.notified_users(self)
            notified.reject! {|user| !user.allowed_to?(:view_news, project) }
            notified
          else
            notified_users_without_events
          end
        end
      end
    end
  end
end

unless News.included_modules.include? EventNotification::Patches::NewsPatch
  News.send(:include, EventNotification::Patches::NewsPatch)
end
