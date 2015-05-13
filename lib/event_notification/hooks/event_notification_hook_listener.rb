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

      def view_my_account_preferences(context={})
        user  = context[:user]
        f     = context[:form]
        s     = ''

        return s.html_safe unless User.current.admin?

        s << "<p>"
        s << label_tag( "pref_ghost_mode", l(:label_ghost_mode) )
        s << hidden_field_tag( "pref[ghost_mode]", "0" )
        s << check_box_tag( "pref[ghost_mode]", "1", user.pref.ghost_mode == "1", :id => 'pref_ghost_mode' )
        s << "</p>"
        s.html_safe
      end

    end
  end
end
