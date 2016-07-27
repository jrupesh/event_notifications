module EventNotification
  module Hooks
    class EventNotificationHookListener < Redmine::Hook::ViewListener
      render_on :view_groups_memberships_table_row, :partial => "groups/memberships_events"
      render_on :view_groups_memberships_table_header, :inline => "<th/>"

      def view_layouts_base_html_head(context={})
        s = ''
        s << content_tag('div', l(:warning_ghost_mode), :class => 'flash warning') if User.current.ghost?
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
    end
  end
end
