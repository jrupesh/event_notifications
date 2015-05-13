module EventNotification
  module Patches
    module UserPreferencePatch

      def self.included(base) # :nodoc:
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
        end
      end

      module ClassMethods
      end

      module InstanceMethods
        def ghost_mode; self[:ghost_mode] end
        def ghost_mode=(enabled); self[:ghost_mode]=enabled end
      end
    end
  end
end

unless UserPreference.included_modules.include? EventNotification::Patches::UserPreferencePatch
  UserPreference.send(:include, EventNotification::Patches::UserPreferencePatch)
end
