require 'redmine'

require 'event_notification/patches/users_helper_patch'
require 'event_notification/patches/user_patch'
require 'event_notification/patches/project_patch'
require 'event_notification/patches/member_patch'
require 'event_notification/patches/issue_patch'
require 'event_notification/patches/document_patch'
require 'event_notification/patches/journal_patch'
require 'event_notification/patches/message_patch'
require 'event_notification/patches/wiki_content_patch'
require 'event_notification/patches/watchers_controller_patch'
require 'event_notification/patches/groups_controller_patch'
require 'event_notification/patches/principal_memberships_controller_patch'
require 'event_notification/patches/user_preference_patch'
require 'event_notification/patches/custom_field_patch'
require 'event_notification/patches/news_patch'

require 'event_notification/patches/mailer_patch'

ActionDispatch::Callbacks.to_prepare do
  require_dependency 'event_notification/hooks/event_notification_hook_listener'
end

Rails.configuration.to_prepare do
  require 'event_notification/patches/acts_as_watchable_patch'    
end

Redmine::Plugin.register :event_notifications do
  name 'Event Notifications plugin'
  author 'Rupesh J'
  description 'Customizes redmine project notification settings for every project event.'
  version '2.3.0'
  author_url 'mailto:rupeshj@esi-group.com'

  settings :default => {
    'enable_event_notifications'        => false,
    'issue_cf_notifications'            => [],
    'issue_category_notifications'      => [],
    'issue_involved_in_related_notified'=> nil,
    'issue_relation_attachment_notified'=> false,
    'event_notifications_with_author'   => false },
  	:partial => 'settings/event_notifications_settings'
end
