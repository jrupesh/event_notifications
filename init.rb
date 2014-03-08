require 'patches/users_helper_patch'
require 'patches/user_patch'
require 'patches/project_patch'
require 'patches/member_patch'
require 'patches/issue_patch'
require 'patches/document_patch'
require 'patches/journal_patch'
require 'patches/message_patch'
require 'patches/wiki_content_patch'
require 'patches/watchers_controller_patch'
require 'patches/groups_controller_patch'

Redmine::Plugin.register :event_notifications do
  name 'Event Notifications plugin'
  author 'Rupesh J'
  description 'Customizes redmine project notification settings for every project event.'
  version '2.0.0'
  author_url 'mailto:rupeshj@esi-group.com'

  settings :default => {
    'enable_event_notifications' => false,
    'issue_cf_notifications'  => [],
    'issue_category_notifications'  => [] },
  	:partial => 'settings/event_notifications_settings'
end
