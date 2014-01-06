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
      def notified_users_with_events(object=none)
        members.select {|m| m.principal.present? && ( (m.mail_notification? && m.principal.notify_about_with_event?(object) ) ||
            m.principal.mail_notification == 'all')}.collect {|m| m.principal}
      end
    end
  end
end

Project.send(:include, Patches::ProjectPatch)