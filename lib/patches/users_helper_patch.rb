module Patches
  module UsersHelperPatch

    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable
      end
    end

    module InstanceMethods

    	def render_project_events_lists(project, show=true)
        s = ''
        if Setting.plugin_event_notifications["enable_event_notifications"] == "on"
          available_events = {'document_added'        => "ev_document_added",
                              'issue_added'           => "ev_issue_added",
                              'issue_updated'         => "ev_issue_updated",
                              'issue_note_added'      => "ev_issue_note_added",
                              'issue_status_updated'  => "ev_issue_status_updated",
                              'issue_priority_updated'=> "ev_issue_priority_updated",
                              'file_added'            => "ev_file_added",
                              'message_posted'        => "ev_message_posted",
                              'news_added'            => "ev_news_added",
                              'wiki_content_added'    => "ev_wiki_content_added",
                              'wiki_content_updated'  => "ev_wiki_content_updated" }

          displaycontent = show == true ? "" : ", style='display:none;'"
          s << "<fieldset class='box'#{displaycontent}>"

          cssclass = ["splitcontentleft","splitcontentright"]
          var = 0
          user_project_events = @user.notified_projects_events(project)
          user_project_events = [] if user_project_events.nil?

          available_events.each do |event, event_label|
            next if !Setting.notified_events.include?(event)

            if event.include?("issue_")
              project.trackers.each do |tracker|
                tracker_event = event.sub('issue') { tracker.name.downcase }

                s <<  content_tag('label',
                        check_box_tag(
                          'user[notified_project_ids][]',
                          {project.id => tracker_event},
                          user_project_events.include?(tracker_event),
                          :id => nil) + " \"#{tracker.name}\" " + l(event_label.sub('issue_'){''}.to_sym) , :class => cssclass[var])
                var = var == 0 ? 1 : 0
              end
            else
              s <<  content_tag('label',
                      check_box_tag(
                        'user[notified_project_ids][]',
                        {project.id => event},
                        user_project_events.include?(event),
                        :id => nil) + ' ' + l(event_label.to_sym) , :class => cssclass[var])
              var = var == 0 ? 1 : 0
            end
          end
          s << "</fieldset>"
        end
        s.html_safe
      end
    end
  end
end

UsersHelper.send(:include, Patches::UsersHelperPatch)