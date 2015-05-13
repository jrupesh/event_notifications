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

GroupsController.send(:include, Patches::GroupsControllerPatch)