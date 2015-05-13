require_dependency 'mailer'

module Patches
  module MailerPatch
    unloadable

    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)
      base.instance_eval do
        alias_method_chain :attachments_added, :events
        alias_method :old_mail, :mail

        define_method(:mail) do |headers={}, &block|
          headers.reverse_merge! 'X-Mailer' => 'Redmine',
                  'X-Redmine-Host' => Setting.host_name,
                  'X-Redmine-Site' => Setting.app_title,
                  'X-Auto-Response-Suppress' => 'All',
                  'Auto-Submitted' => 'auto-generated',
                  'From' => redmine_from,
                  'List-Id' => "<#{Setting.mail_from.to_s.gsub('@', '.')}>"

        # Replaces users with their email addresses
        [:to, :cc, :bcc].each do |key|
          if headers[key].present?
            headers[key] = self.class.email_addresses(headers[key])
          end
        end

        # Removes the author from the recipients and cc
        # if the author does not want to receive notifications
        # about what the author do
        if @author && @author.logged? && @author.pref.no_self_notified
          addresses = @author.mails
          headers[:to] -= addresses if headers[:to].is_a?(Array)
          headers[:cc] -= addresses if headers[:cc].is_a?(Array)
        end

        if @author && @author.logged?
          redmine_headers 'Sender' => @author.login
        end

        # Blind carbon copy recipients
        if Setting.bcc_recipients?
          headers[:bcc] = [headers[:to], headers[:cc]].flatten.uniq.reject(&:blank?)
          headers[:to] = nil
          headers[:cc] = nil
        end

        if @message_id_object
          headers[:message_id] = "<#{self.class.message_id_for(@message_id_object)}>"
        end
        if @references_objects
          headers[:references] = @references_objects.collect {|o| "<#{self.class.references_for(o)}>"}.join(' ')
        end

        m = if block_given?
          super headers, &block
        else
          super headers do |format|
            format.text
            format.html unless Setting.plain_text_mail?
          end
        end
        set_language_if_valid @initial_language

        m
        end
      end
    end

    module ClassMethods
    end

    module InstanceMethods
	    def attachments_added_with_events(attachments)
	    	if Setting.plugin_event_notifications["enable_event_notifications"] == "on"
			    container = attachments.first.container
			    added_to = ''
			    added_to_url = ''
			    @author = attachments.first.author
			    case container.class.name
			    when 'Project'
			      added_to_url = url_for(:controller => 'files', :action => 'index', :project_id => container)
			      added_to = "#{l(:label_project)}: #{container}"
			      recipients = container.project.notified_users(container).select {|user| user.allowed_to?(:view_files, container.project)}.collect  {|u| u.mail}
			    when 'Version'
			      added_to_url = url_for(:controller => 'files', :action => 'index', :project_id => container.project)
			      added_to = "#{l(:label_version)}: #{container.name}"
			      recipients = container.project.notified_users(container).select {|user| user.allowed_to?(:view_files, container.project)}.collect  {|u| u.mail}
			    when 'Document'
			      added_to_url = url_for(:controller => 'documents', :action => 'show', :id => container.id)
			      added_to = "#{l(:label_document)}: #{container.title}"
			      recipients = container.recipients
			    end
			    redmine_headers 'Project' => container.project.identifier
			    @attachments = attachments
			    @added_to = added_to
			    @added_to_url = added_to_url
			    mail :to => recipients,
			      :subject => "[#{container.project.name}] #{l(:label_attachment_new)}"
		    else
		    	attachments_added_without_events(attachments)
		    end
      end

      def redmine_from
        return Setting.mail_from if @author.nil?
        case Setting.plugin_event_notifications["event_notifications_with_author"]
        when "author"
          "\"#{@author.name} [REDMINE]\" <#{@author.mail}>"
        when "authorname"
          "\"#{@author.name} [REDMINE]\" <#{Setting.mail_from.sub(/.*?</, '').gsub(">", "")}>"
        else
          Setting.mail_from
        end
      end

      def quality_tree_comment_added(comment,users,subject="")
        news = comment.commented
        redmine_headers 'Project' => news.project.identifier
        @author = comment.author
        message_id comment
        references news
        @news = news
        @comment = comment
        if comment.commented.is_a?(Issue)
          @news_url = url_for(:controller => 'issues', :action => 'show', :id => news)
        else
          @news_url = url_for(:controller => 'news', :action => 'show', :id => news)
        end
        mail :to => users.map(&:mail),
         :subject => "[#{news.project.name}] #{subject}: #{comment.author} mentioned you in a note."
      end

      def quality_tree_comment_notifiers(comment,users,subject="")
        news = comment.commented
        redmine_headers 'Project' => news.project.identifier
        @author = comment.author
        message_id comment
        references news
        @news = news
        @comment = comment
        if comment.commented.is_a?(Issue)
          @news_url = url_for(:controller => 'issues', :action => 'show', :id => news)
        elsif comment.commented.is_a?(News)
          @news_url = url_for(:controller => 'news', :action => 'show', :id => news)
        else
          @news_url = signin_path
        end
        mail :bcc => users.map(&:mail),
         :subject => "[#{news.project.name}] #{subject}: #{comment.author} added a note."
      end
    end
  end
end

Rails.configuration.to_prepare do
  Mailer.send(:include, Patches::MailerPatch)
end