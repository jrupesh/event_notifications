module Patches
  module UserPatch

    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable
        alias_method_chain :update_notified_project_ids, :events
        alias_method_chain :notify_about?, :event
      end
    end

    module InstanceMethods
      #TODO : Check Project#notified_users. This needs to be aliased to user#notify_about?
      def update_notified_project_ids_with_events
        if @notified_projects_ids_changed
          logger.debug("PATCH - update_notified_project_ids notified_projects_ids #{notified_projects_ids}")
          ids = (mail_notification == 'selected' ? Array.wrap(notified_projects_ids).reject(&:blank?) : [])
          ids_hash = {}
          ids.each do |h|
            eval(h).each do |key, value|
              ids_hash.has_key?(key) ? ids_hash[key] << value : ids_hash[key] = [value]
            end
          end
          members.update_all(:mail_notification => false)
          if ids_hash.keys.any?
            members.where(:project_id => ids_hash.keys).update_all(:mail_notification => true)
            members.each { |m| m.update_attributes!(:events => ids_hash[m.project_id]) if ids_hash.keys.include?(m.project_id) }
          end
        end
      end

    	def notified_projects_events(project)
        #For a given project, Return the list of events selected by the user.
        proj_events = Hash[memberships.map { |m| [m.project_id, m.events] }]
        proj_events.has_key?(project.id) ? proj_events[project.id] : []
      end

      def check_user_events(object)
        case object
        when Issue
          #Assumption (Dirty Check) - Created on date is older than a 30 sec. (Issue updated)
          event = 'issue_added'
          if Time.now - object.created_on > 30
            event = 'issue_updated'
          end
          notified_projects_events(object.project).include?(event)
        when News
          notified_projects_events(object.project).include?("news_added")
        when WikiContent
          event = 'wiki_content_added'
          if Time.now - object.created_on > 30
            event = 'wiki_content_updated'
          end
          notified_projects_events(object.project).include?(event)
        when Document
          notified_projects_events(object.project).include?("document_added")
        # when File
        #   notified_projects_events(object.project).include?("file_added")
        when Message
          notified_projects_events(object.project).include?("message_posted")
        # Below are wrt to ISSUE notifications.
        when Journal
          if object.notes.present?
            notified_projects_events(object.project).include?("issue_note_added")
          elsif object.new_status.present?
            notified_projects_events(object.project).include?("issue_status_updated") 
          elsif object.new_value_for('priority_id').present?
            notified_projects_events(object.project).include?("issue_priority_updated") 
          else
            false
          end
        end
      end

      def notify_about_with_event?(object)
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
            when 'only_my_events'
              # user receives notifications for created/assigned issues on unselected projects
              object.author == self || is_or_belongs_to?(object.assigned_to) || is_or_belongs_to?(object.assigned_to_was)
            when 'selected'
              # user receives notifications for created/assigned issues on unselected projects
              object.author == self || is_or_belongs_to?(object.assigned_to) || is_or_belongs_to?(object.assigned_to_was) || 
              check_user_events(object)
              #How to check if the object is newly created or updated.
            when 'only_assigned'
              is_or_belongs_to?(object.assigned_to) || is_or_belongs_to?(object.assigned_to_was)
            when 'only_owner'
              object.author == self
            end
          when News, Journal, Message, Document, WikiContent
            check_user_events(object)
          end
        end
      end
    end
  end
end

User.send(:include, Patches::UserPatch)
