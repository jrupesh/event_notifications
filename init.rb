require 'patches/users_helper_patch'
require 'patches/user_patch'
require 'patches/project_patch'
require 'patches/member_patch'
require 'patches/issue_patch'
require 'patches/document_patch'
require 'patches/journal_patch'
require 'patches/message_patch'
require 'patches/wiki_content_patch'

Redmine::Plugin.register :event_notifications do
  name 'Event Notifications plugin'
  author 'Rupesh J'
  description 'Customizes redmine project notification settings for every project event.'
  version '0.0.1'
  #url 'http://example.com/path/to/plugin'
  author_url 'mailto:rupeshj@esi-group.com'
end
