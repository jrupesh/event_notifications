module Patches
  module DocumentPatch

    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable
        alias_method_chain :recipients, :events
      end
    end

    module InstanceMethods
	    def recipients_with_events
        if Setting.plugin_event_notifications["enable_event_notifications"] == "on"
  	      notified =  project.notified_users(self)
  	      notified.reject! {|user| !visible?(user)}
  	      notified.collect(&:mail)
        else
          recipients_without_events
        end
	    end
    end
  end
end

Document.send(:include, Patches::DocumentPatch)
