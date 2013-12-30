module Patches
  module UserPatch

    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable
      end
    end

    module InstanceMethods
      #TODO : Check Project#notified_users. This needs to be aliased to user#notify_about?

    	def notified_projects_events(project)
        #For a given project, Return the list of events selected by the user.
      end

      def event_notify_about?(object)
        #Update this method with all the events cases.
        #Alias the old method notify_about?(object)

        if mail_notification == 'all'
          true
        elsif mail_notification.blank? || mail_notification == 'none'
          false
        else
          case object
          when Issue
            case mail_notification
            when 'selected', 'only_my_events'
              # user receives notifications for created/assigned issues on unselected projects
              object.author == self || is_or_belongs_to?(object.assigned_to) || is_or_belongs_to?(object.assigned_to_was)
            when 'only_assigned'
              is_or_belongs_to?(object.assigned_to) || is_or_belongs_to?(object.assigned_to_was)
            when 'only_owner'
              object.author == self
            end
          when News
            # always send to project members except when mail_notification is set to 'none'
            true
          end
        end
      end


    end
  end
end

User.send(:include, Patches::UserPatch)