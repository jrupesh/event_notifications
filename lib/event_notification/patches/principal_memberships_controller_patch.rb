module Patches
  module PrincipalMembershipsControllerPatch

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

PrincipalMembershipsController.send(:include, Patches::PrincipalMembershipsControllerPatch)