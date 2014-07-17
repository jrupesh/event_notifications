require 'redmine'

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

require 'patches/mailer_patch'

Redmine::Plugin.register :event_notifications do
  name 'Event Notifications plugin'
  author 'Rupesh J'
  description 'Customizes redmine project notification settings for every project event.'
  version '2.0.0'
  author_url 'mailto:rupeshj@esi-group.com'

  settings :default => {
    'enable_event_notifications'        => false,
    'issue_cf_notifications'            => [],
    'issue_category_notifications'      => [],
    'event_notifications_with_author'   => false },
  	:partial => 'settings/event_notifications_settings'
end

# RedmineApp::Application.config.after_initialize do
#   class Mailer

#     alias_method :old_mail, :mail

#     def redmine_from(sender=nil)
#       user = sender || @author
#       (user.nil? ? "Redmine messenger" : user.name) + " [Redmine] <#{user.nil? ? Setting.mail_from : user.mail}>"
#     end

#     def mail(headers={}, &block)
#       headers.merge! 'X-Mailer' => 'Redmine',
#               'X-Redmine-Host' => Setting.host_name,
#               'X-Redmine-Site' => Setting.app_title,
#               'X-Auto-Response-Suppress' => 'OOF',
#               'Auto-Submitted' => 'auto-generated',
#               'From' => redmine_from,
#               'List-Id' => "<#{Setting.mail_from.to_s.gsub('@', '.')}>"

#       logger.debug("MAILER: #{redmine_from}")

#       # Removes the author from the recipients and cc
#       # if the author does not want to receive notifications
#       # about what the author do
#       if @author && @author.logged? && @author.pref.no_self_notified
#         headers[:to].delete(@author.mail) if headers[:to].is_a?(Array)
#         headers[:cc].delete(@author.mail) if headers[:cc].is_a?(Array)
#       end

#       if @author && @author.logged?
#         redmine_headers 'Sender' => @author.login
#       end

#       # Blind carbon copy recipients
#       if Setting.bcc_recipients?
#         headers[:bcc] = [headers[:to], headers[:cc]].flatten.uniq.reject(&:blank?)
#         headers[:to] = nil
#         headers[:cc] = nil
#       end

#       if @message_id_object
#         headers[:message_id] = "<#{self.class.message_id_for(@message_id_object)}>"
#       end
#       if @references_objects
#         headers[:references] = @references_objects.collect {|o| "<#{self.class.references_for(o)}>"}.join(' ')
#       end

#       m = if block_given?
#         super headers, &block
#       else
#         super headers do |format|
#           format.text
#           format.html unless Setting.plain_text_mail?
#         end
#       end
#       set_language_if_valid @initial_language

#       m
#     end
#     # alias_method_chain :mail, :esi

#   end if defined? Mailer
# end