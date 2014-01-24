module Patches
  module MemberPatch

    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable
        serialize :events

      
      end


    end

    module InstanceMethods
      def getAvailableProjectEvents(project)
        available_events_label = {}
        if Setting.plugin_event_notifications["enable_event_notifications"] == "on"
          AVAILABLE_EVENTS.each do |event, event_label|
            next if !Setting.notified_events.include?(event)

            if event.include?("issue_")
              project.trackers.each do |tracker|
                tracker_event = event.sub('issue') { tracker.name.downcase }
                available_events_label[tracker_event] = [ tracker.name , event_label]
              end
            else
              available_events_label[event] = ["", event_label]
            end
          end
        end
        available_events_label
      end

      def events_group=(arg)
        events = arg
        if user && user.is_a?(Group) && arg.length > 0

        end
      end
    end

    module ClassMethods

      def AVAILABLE_EVENTS
        events = {'issue_added'           => "ev_issue_added",
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
                            'wiki_content_updated'  => "ev_wiki_content_updated" }  
      end

      def update_events!
        #Update all the events with respect to the project notifications.
        events_available = Setting.notified_events
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
