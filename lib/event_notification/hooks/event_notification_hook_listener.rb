module Hooks
  class EventNotificationHookListener < Redmine::Hook::ViewListener
    render_on :view_groups_memberships_table_row, :partial => "groups/memberships_events"
    render_on :view_groups_memberships_table_header, :inline => "<th/>"
  end
end
