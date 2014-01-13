module Patches
  module MailerPatch

    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable
        alias_method_chain :attachments_added, :events
      end
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
		    	attachments_added_without_events
		    end
      end
    end
  end
end

Mailer.send(:include, Patches::MailerPatch)







