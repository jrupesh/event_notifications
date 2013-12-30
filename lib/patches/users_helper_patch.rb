module Patches
  module UsersHelperPatch

    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable
      end
    end

    module InstanceMethods

    	def render_project_events_lists(project)

        available_events = {'document_added'        => "ev_document_added",
                            'file_added'            => "ev_file_added",
                            'issue_added'           => "ev_issue_added",
                            'issue_updated'         => "ev_issue_updated",
                            'issue_note_added'      => "ev_issue_note_added",
                            'issue_status_updated'  => "ev_issue_status_updated",
                            'issue_priority_updated'=> "ev_issue_priority_updated",
                            'message_posted'        => "ev_message_posted",
                            'news_added'            => "ev_news_added",
                            'wiki_content_added'    => "ev_wiki_content_added",
                            'wiki_content_updated'  => "ev_wiki_content_updated" }

        s = ''
        s << "<fieldset class='box', style='display:none;'"

        cssclass = ["splitcontentleft","splitcontentright"]
        var = 0
        available_events.each do |event, event_label|
          # next if !Setting.notified_events.include?(event)
          s <<  content_tag('label',
                  check_box_tag(
                    'user[notified_project_ids][]',
                    {project.id => event},
                    @user.notified_projects_ids.include?(project.id),
                    :id => nil) + ' ' + l(event_label.to_sym) , :class => cssclass[var])
          var = var == 0 ? 1 : 0
        end
        s << "</fieldset>"
        s.html_safe
      end
    end
  end
end

UsersHelper.send(:include, Patches::UsersHelperPatch)