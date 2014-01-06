module Patches
  module WikiContentPatch

    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable
        alias_method_chain :recipients, :events
      end
    end

    module InstanceMethods
      def recipients_with_events
        notified = project.notified_users(self)
        notified.reject! {|user| !visible?(user)}
        notified.collect(&:mail)
      end
    end
  end
end

WikiContent.send(:include, Patches::WikiContentPatch)