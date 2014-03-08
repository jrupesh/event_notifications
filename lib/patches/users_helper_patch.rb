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
        return if !Setting.notified_events.any?
        s = ''
        if Setting.plugin_event_notifications["enable_event_notifications"] == "on"
          displaycontent = show == true ? "" : ", style='display:none;'"
          s << "<fieldset class='box'#{displaycontent}>"

          cssclass = ["splitcontentleft","splitcontentright"]
          var = 0
          user_project_events = @user.notified_projects_events(project)
          user_project_events = [] if user_project_events.nil?

          Member::AVAILABLE_EVENTS.each do |event, event_label|
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

          s << customfields_issuecategories(project,user_project_events,'user[notified_project_ids][]')

          s << "</fieldset>"
        end
        return "" if !s.include?("label")
        s.html_safe
      end

      def customfields_issuecategories(project,user_project_events, html_id)
        s = ""
        Setting.plugin_event_notifications["issue_cf_notifications"].each do |cf|
          next if cf.blank? || cf.nil?
          custom_fields = project.all_issue_custom_fields
          cf_ids = custom_fields.map(&:id)
          next if !cf_ids.include?(cf.to_i)
          cf_obj = custom_fields.fetch(cf_ids.index(cf.to_i))

          selected_value_list = user_project_events.select { |e| e if e.include?("CF#{project.id}-#{cf}-")}
          selected_value = selected_value_list.any? ? 
            selected_value_list.collect{|k| "{#{project.id} => \'#{k}\'}"} :
            ""

          s <<  "<div><label>#{cf_obj.name} "
          s <<  select_tag( html_id,
              options_for_select( [["-", "{#{project.id} => \'\'}" ]] + 
              cf_obj.possible_values.collect{|g| [g.to_s, "{#{project.id} => \'CF#{project.id}-#{cf}-#{g.to_s}\'}" ]}, selected_value),
              :id => nil, :multiple => true)
          s << "</label></div>"
        end

        if Setting.plugin_event_notifications["issue_category_notifications"].include?(project.id.to_s)
          selected_value_list = user_project_events.select { |e| e if e.include?("IC-")}
          selected_value = selected_value_list.any? ? 
            selected_value_list.collect{|k| "{#{project.id} => \'#{k}\'}"} :
            ""
          label = "Issue Category"

          s <<  "<div><label>#{label} "
          s <<  select_tag( html_id,
              options_for_select( [["-", "{#{project.id} => \'\'}" ]] + 
              project.issue_categories.collect{|g| [g.name, "{#{project.id} => \'IC-#{g.id}\'}" ]}, selected_value),
              :id => nil, :multiple => true)
          s <<  "</label></div>"
        end
        s    
      end
    end
  end
end

UsersHelper.send(:include, Patches::UsersHelperPatch)