module EventNotification
  module Hooks
    class EventNotificationHookListener < Redmine::Hook::ViewListener
      render_on :view_groups_memberships_table_row, :partial => "groups/memberships_events"
      render_on :view_groups_memberships_table_header, :inline => "<th/>"

      def view_layouts_base_html_head(context={})
        s = ''
        s << content_tag('div', l(:warning_ghost_mode), :class => 'flash warning') if User.current.ghost?
        if User.current.admin_ghost?
          s << content_tag('div', l(:warning_admin_ghost_mode), :class => 'flash error nodata')
        elsif !ActiveRecord::Base.record_timestamps
          s << content_tag('div', l(:warning_admin_ghost_mode_users), :class => 'flash error nodata')
          s << javascript_tag("function disableallInputs(){
              $('input, textarea, select').prop('disabled', true);
            };
            $(document).ready(disableallInputs);")
        end
        s.html_safe
      end

      def view_users_form_preferences(context={})
        return ''.html_safe unless User.current.admin?
        user  = context[:user]
        f     = context[:form]
        ghost_mode_html(user)
      end

      def view_my_account_preferences(context={})
        return ''.html_safe unless User.current.admin?
        user  = context[:user]
        f     = context[:form]

        ghost_mode_html(user)
      end

      def ghost_mode_html(user)
        s = ''
        s << "<p>"
        s << label_tag( "pref_ghost_mode", l(:label_ghost_mode) )
        s << hidden_field_tag( "pref[ghost_mode]", "0" )
        s << check_box_tag( "pref[ghost_mode]", "1", user.pref.ghost_mode == "1", :id => 'pref_ghost_mode' )
        s << "</p>"

        return s.html_safe unless user.admin?

        s << "<p title='#{l(:label_admin_ghost_tooltip)}' style='color: red; border-bottom: 1px dotted #aaa; cursor: help;'>"
        s << label_tag( "pref_admin_ghost_mode", l(:label_admin_ghost_mode), :style => 'cursor: help;')
        s << hidden_field_tag( "pref[admin_ghost_mode]", "0" )
        s << check_box_tag( "pref[admin_ghost_mode]", "1", user.pref.admin_ghost_mode == "1", :id => 'pref_admin_ghost_mode' )
        s << "</p>"
        s.html_safe
      end

      def view_custom_fields_form_issue_custom_field(context={})
        custom_field  = context[:custom_field]
        f             = context[:form]
        s     = ''
        s << "<p>"
        s << f.check_box(:disable_notification)
        s << "</p>"
        s.html_safe
      end

      def view_projects_form(context = { })
        s = ""
        f = context[:form]
        project = context[:project]
        s << content_tag(:p, f.check_box(:notify_non_member))
        s.html_safe
      end
    end
  end
end
