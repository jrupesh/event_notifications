module EventNotification
  module Patches
    module CustomFieldPatch

      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
        end
      end

      module InstanceMethods
        def disable_notification
          format_store[:disable_notification] == "1"
        end

        def disable_notification=(arg)
          format_store[:disable_notification] = arg
        end
      end
    end
  end
end

unless CustomField.included_modules.include? EventNotification::Patches::CustomFieldPatch
  CustomField.send(:include, EventNotification::Patches::CustomFieldPatch)
end
