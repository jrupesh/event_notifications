module EventNotification
  module Patches
    module UserPatch

      def self.included(base) # :nodoc:
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
          alias_method_chain 'notified_project_ids=', 'events'
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
        def notified_events_projects_ids
          @notified_events_projects_ids ||= memberships.select { |m| m.events.reject{ |x| !x.is_a?(String) }.any? }.collect(&:project_id)
        end

        def ghost?
          self.admin? && self.pref[:ghost_mode] == '1'
        end

        def notified_project_ids_with_events=(ids)
          logger.debug("Event Notifications: PATCH - notified_project_ids_with_events ids #{ids}")
          if Setting.plugin_event_notifications["enable_event_notifications"] == "on"
            @notified_projects_ids_changed = true
            @notified_projects_ids = ids
          else
            logger.debug("Event Notifications: PATCH - Event Notification Not enabled #{ids}")
            # notified_project_ids_without_events = ids # Commented coz test fails.
            @notified_projects_ids_changed = true
            @notified_projects_ids = ids.map(&:to_i).uniq.select {|n| n > 0}
          end
        end

        #TODO : Check Project#notified_users. This needs to be aliased to user#notify_about?
        def update_notified_project_ids_with_events
          if Setting.plugin_event_notifications["enable_event_notifications"] == "on"
            if @notified_projects_ids_changed
              logger.debug("Event Notifications: PATCH - update_notified_project_ids notified_projects_ids #{notified_projects_ids}")
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

        def default_notifier
          @default_notifier ||= false
        end

        def default_notifier=(arg)
          @default_notifier = arg
        end

        def loaded_memberships
          @loaded_memberships ||= memberships
        end

        def loaded_memberships=(arg)
          @loaded_memberships = arg
        end

      	def notified_projects_events(project)
          #For a given project, Return the list of events selected by the user.
          proj_events = Hash[loaded_memberships.map { |m| [m.project_id, m.events.reject{ |x| !x.is_a?(String) } ] }]
          proj_events.has_key?(project.id) ? proj_events[project.id] : []
        end

        def check_user_events(object)
          # logger.debug("Event Notifications: Checking User Notification for #{self.name}.")
          case object
          when Issue
            return true if default_notifier
            return false if object.current_journal && ( (object.current_journal.only_attachments && !pref.attachment_notification ) ||
              (object.current_journal.only_relations   && !pref.relation_notification) )
            return true  if (object.author == self) || is_or_belongs_to?(object.assigned_to) || is_or_belongs_to?(object.assigned_to_was)
            return false if !notified_projects_events(object.project).any?

            # logger.debug("Event Notifications: Issue.")
            event = object.is_issue_new_record? == 1 ? 'issue_added' : 'issue_updated'
            tracker_event = event.sub('issue') { object.tracker.name.downcase }
            events = notified_projects_events(object.project)
            return true if events.include?(tracker_event) == true

            object.custom_field_values.each do |cfv|
              return true if cfv.custom_field.field_format == 'user' && cfv.value.to_s == self.id.to_s
              return true if events.include?("CF#{object.project.id}-#{cfv.custom_field.id}-#{cfv.value}") == true
            end

            return true if !object.category.nil? && events.include?("IC-#{object.category.id}") == true

            if object.is_issue_new_record? != 1 && object.current_journal
              journal_obj = object.current_journal
              return true if journal_obj.new_status.present? && events.include?("issue_status_updated".sub('issue'){ object.tracker.name.downcase })
              return true if journal_obj.new_value_for('priority_id').present? && events.include?("issue_priority_updated".sub('issue'){ object.tracker.name.downcase })
              return true if journal_obj.notes.present? && events.include?("issue_note_added".sub('issue'){ object.tracker.name.downcase })
            end
            return false
          when News
            object.comments_count > 0 ? notified_projects_events(object.project).include?("news_comment_added") :
              notified_projects_events(object.project).include?("news_added")
          when WikiContent
            event = object.version > 1 ? 'wiki_content_updated' : 'wiki_content_added'
            notified_projects_events(object.project).include?(event)
          when Document
            # logger.debug("Event Notifications: Notifications for user #{id} #{login} #{object.project_id} #{notified_projects_events(object.project)}")
            notified_projects_events(object.project).include?("document_added")
          when Version
            notified_projects_events(object.project).include?("file_added")
          when Project
            notified_projects_events(object).include?("file_added")
          when Message
            notified_projects_events(object.project).include?("message_posted-board-#{object.board_id}")
          end
        end

        def notify_about_with_event?(object)
          return false if self.class.get_notification == false || User.current.ghost?
          if Setting.plugin_event_notifications["enable_event_notifications"] == "on"
            logger.debug("Event Notifications: Mail notification option for #{self.name} : #{mail_notification} : #{object.class.name}")
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
                  object.author == self || is_or_belongs_to?(object.assigned_to) || is_or_belongs_to?(object.assigned_to_was) || default_notifier
                when 'selected'
                  # user receives notifications for created/assigned issues on unselected projects
                  check_user_events(object)
                  #How to check if the object is newly created or updated.
                when 'only_assigned'
                  is_or_belongs_to?(object.assigned_to) || is_or_belongs_to?(object.assigned_to_was)
                when 'only_owner'
                  object.author == self
                end
              when News, Journal, Message, Document, WikiContent
                notified_projects_events(object.project).any? && check_user_events(object)
              end
            end
          else
            notify_about_without_event?(object)
          end
        end
      end
    end
  end
end

unless User.included_modules.include? EventNotification::Patches::UserPatch
  User.send(:include, EventNotification::Patches::UserPatch)
end

