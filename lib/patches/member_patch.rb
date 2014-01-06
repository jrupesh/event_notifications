module Patches
  module MemberPatch

    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable
        serialize :events
      end
    end

    module InstanceMethods
    end
  end
end

Member.send(:include, Patches::MemberPatch)
