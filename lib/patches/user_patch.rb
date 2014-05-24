module Patches
  module UserPatch

    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable
        # cattr_accessor     :notification_enabled => true
        alias_method_chain :update_notified_project_ids, :events
        alias_method_chain :notify_about?, :event
      end
    end

    module ClassMethods
      @@notification_enabled = true

      def get_notification
        @@notification_enabled
      end

      def set_notification(value)
        @@notification_enabled = value
      end

    end

    module InstanceMethods
      #TODO : Check Project#notified_users. This needs to be aliased to user#notify_about?
      def update_notified_project_ids_with_events
        if Setting.plugin_event_notifications["enable_event_notifications"] == "on"
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
        else
          update_notified_project_ids_without_events
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
          #Assumption (Dirty Check) - Time now and Created on  is not older than 5 sec. (Issue updated)
          event = Time.now - object.created_on < 5 ? 'issue_added' : 'issue_updated'
          #Assumption (Dirty Check) - Created on and modified date is not older than 5 sec. (Issue updated)
          # event = object.updated_on - object.created_on < 5 ? 'issue_added' : 'issue_updated'
          tracker_event = event.sub('issue') { object.tracker.name.downcase }
          events = notified_projects_events(object.project)
          return true if events.include?(tracker_event) == true

          object.custom_field_values.each do |cfv|
            return true if events.include?("CF#{object.project.id}-#{cfv.custom_field.id}-#{cfv.value}") == true
          end

          return true if !object.category.nil? && events.include?("IC-#{object.category.id}") == true

          return false
        when News
          object.comments_count > 0 ? notified_projects_events(object.project).include?("news_comment_added") :
            notified_projects_events(object.project).include?("news_added")
        when WikiContent
          event = object.version > 1 ? 'wiki_content_updated' : 'wiki_content_added'
          notified_projects_events(object.project).include?(event)
        when Document
          notified_projects_events(object.project).include?("document_added")
        when Version
          notified_projects_events(object.project).include?("file_added")
        when Project
          notified_projects_events(object).include?("file_added")
        when Message
          notified_projects_events(object.project).include?("message_posted")
        # Below are wrt to ISSUE notifications.
        when Journal
          status = false
          if object.new_status.present?
            status = notified_projects_events(object.project).include?("issue_status_updated".sub('issue'){ object.journalized.tracker.name.downcase })
          elsif object.new_value_for('priority_id').present?
            status = notified_projects_events(object.project).include?("issue_priority_updated".sub('issue'){ object.journalized.tracker.name.downcase })
          end
          
          if object.notes.present? && !status
            status = notified_projects_events(object.project).include?("issue_note_added".sub('issue'){ object.journalized.tracker.name.downcase })
          else
            false
          end
          status
        end
      end

      def notify_about_with_event?(object)
        return false if self.class.get_notification == false
        if Setting.plugin_event_notifications["enable_event_notifications"] == "on"
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
        else
          notify_about_without_event?(object)
        end
      end
    end
  end
end

User.send(:include, Patches::UserPatch)
