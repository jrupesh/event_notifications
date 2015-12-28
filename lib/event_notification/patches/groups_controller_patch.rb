module EventNotification
  module Patches
    module GroupsControllerPatch

      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
          helper :users
        end
      end

      module InstanceMethods
      end
    end
  end
end

unless GroupsController.included_modules.include? EventNotification::Patches::GroupsControllerPatch
  GroupsController.send(:include, EventNotification::Patches::GroupsControllerPatch)
end
