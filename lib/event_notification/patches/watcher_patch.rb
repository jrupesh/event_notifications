module EventNotification
  module Patches
    module WatcherPatch

      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
          after_create :send_notification
        end
      end

      module InstanceMethods
        def initialize(*args)
          super
          self.notify = false if watchable && watchable.new_record?
        end

        def send_notification
          if notify? && User.current != user && Setting.plugin_event_notifications["enable_event_notifications"] == "on" &&
              Setting.plugin_event_notifications["enable_watcher_notification"] == 'on' && user.mail.present? &&
              user.mail_notification != 'none'

            return if watchable.is_a?(Issue) && watchable.project.notified_users_with_events(watchable).map(&:id).include?(user_id)

            Mailer.watcher_added(self, User.current).deliver
          end
        end

        def notify?
          @notify != false
        end

        def notify=(arg)
          @notify = arg
        end
      end
    end
  end
end

unless Watcher.included_modules.include? EventNotification::Patches::WatcherPatch
  Watcher.send(:include, EventNotification::Patches::WatcherPatch)
end
