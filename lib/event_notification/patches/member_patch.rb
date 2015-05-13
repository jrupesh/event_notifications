module Patches
  module MemberPatch

    def self.included(base) # :nodoc:
      base.const_set('AVAILABLE_EVENTS',Patches::MemberPatch::EventsConstant::AVAILABLE_EVENTS)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)
      base.class_eval do
        unloadable
        serialize :events, Array
      end
    end

    module EventsConstant
      AVAILABLE_EVENTS = {'issue_added'           => "ev_issue_added",
                          'issue_updated'         => "ev_issue_updated",
                          'issue_note_added'      => "ev_issue_note_added",
                          'issue_status_updated'  => "ev_issue_status_updated",
                          'issue_priority_updated'=> "ev_issue_priority_updated",
                          'document_added'        => "ev_document_added",
                          'file_added'            => "ev_file_added",
                          'message_posted'        => "ev_message_posted",
                          'news_added'            => "ev_news_added",
                          'news_comment_added'    => "ev_news_comment_added",
                          'wiki_content_added'    => "ev_wiki_content_added",
                          'wiki_content_updated'  => "ev_wiki_content_updated" }.freeze
    end

    module InstanceMethods
      def getAvailableProjectEvents(project)
        available_events_label = {}
        if Setting.plugin_event_notifications["enable_event_notifications"] == "on"
          Member::AVAILABLE_EVENTS.each do |event, event_label|
            next if !Setting.notified_events.include?(event)

            if event.include?("issue_")
              project.trackers.each do |tracker|
                tracker_event = event.sub('issue') { tracker.name.downcase }
                available_events_label[tracker_event] = [ tracker.name , event_label.sub('issue_'){""}]
              end
            else
              available_events_label[event] = ["", event_label]
            end
          end
        end
        available_events_label
      end

      def events_group=(arg)
        proj_events_hash = {}
        arg.each do |h|
          eval(h).each do |key, value|
            proj_events_hash.has_key?(key) ? proj_events_hash[key] << value : proj_events_hash[key] = [value]
          end
        end
        proj_events_hash.each do | project_id, proj_events |

          if proj_events.length > 0
            events_removed = self.events - proj_events
            # puts "#{events_removed}"
            self.events= proj_events
            self.mail_notification= true

            if principal.is_a?(Group)
              project = Project.find(project_id)

              principal.users.each do |u|
                next if !project.users.include? u
                m = Member.find_by_project_id_and_user_id(project_id, u.id)
                # m = Member.where("project_id = ? and user_id = ?", project_id, u.id).first
                proj_events.each { |e| m.events << e }
                m.events.uniq!
                events_removed.each { |e| m.events.delete(e)}
                m.mail_notification= m.events.length > 0 ? true : false
                m.save
              end
            end
          end
        end
      end
    end

    module ClassMethods
      def update_events!
        #Update all the events with respect to the project notifications.
        events_available = Setting.notified_events
        Member.update_all(:mail_notification => false, :events => [])

        Project.all.each do |p|
          events_to_update = []
          events_available.each do |e|
            if e.include?("issue_")
              p.trackers.each { |tracker|
                events_to_update << e.sub('issue') { tracker.name.downcase }
              }
            else
              events_to_update << e
            end
          end

          members = p.members.select {|m| m.principal.present? &&
            (m.mail_notification? || m.principal.mail_notification == 'all')}

          Member.where(:project_id => [p.id]).update_all(:mail_notification => false, :events => [])
          members.each { |m| m.update_attributes(:mail_notification => true, :events => events_to_update) }
        end
      end
    end
  end
end

Member.send(:include, Patches::MemberPatch)
