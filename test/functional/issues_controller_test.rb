# Redmine - project management software
# Copyright (C) 2006-2013  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require File.expand_path('../../test_helper', __FILE__)

class IssuesControllerTest < ActionController::TestCase
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :attachments,
           :workflows,
           :custom_fields,
           :custom_values,
           :custom_fields_projects,
           :custom_fields_trackers,
           :time_entries,
           :journals,
           :journal_details,
           :queries,
           :repositories,
           :changesets

  include Redmine::I18n

  def setup
    ActionMailer::Base.deliveries.clear
    User.current = nil

    Setting.notified_events = ['issue_added' , 'issue_updated' , 'issue_note_added' ,
      'issue_status_updated' , 'issue_priority_updated', 'document_added' ,
      'file_added' , 'message_posted' , 'news_added' ,
      'news_comment_added' , 'wiki_content_added' , 'wiki_content_updated' ]

    events_available = Setting.notified_events

    Setting.plugin_event_notifications["enable_event_notifications"] = "on"
    Member.update_all(:mail_notification => false, :events => [])
    User.update_all(:mail_notification => 'none')

    role = Role.find(2)
    user = User.find(7)
    project = Project.find(1)
    Member.create!(:principal => user, :project => project, :roles => [role])
  end

  def test_post_create_should_send_a_notification
    project = Project.find(1)
    tracker = Tracker.find(3)

    m = project.members.last
    m.user.update_attributes(:mail_notification => 'selected')
    m.update_attributes(:mail_notification => true, :events => ["#{tracker.name.downcase}_added"])

    ActionMailer::Base.deliveries.clear

    @request.session[:user_id] = 2
    assert_difference 'Issue.count' do
      post :create, :project_id => 1,
                 :issue => {:tracker_id => 3,
                            :subject => 'This is the test_new issue',
                            :description => 'This is the description',
                            :priority_id => 5,
                            :estimated_hours => '',
                            :custom_field_values => {'2' => 'Value for field 2'}}
    end
    assert_redirected_to :controller => 'issues', :action => 'show', :id => Issue.last.id

    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal 1, ActionMailer::Base.deliveries.last.bcc.length
    assert ActionMailer::Base.deliveries.last.bcc.include?('someone@foo.bar')
  end

  def test_post_create_with_attachment_should_notify_with_attachments
    project = Project.find(1)
    tracker = Tracker.find(1)
    m = project.members.last
    m.user.update_attributes(:mail_notification => 'selected')
    m.update_attributes(:mail_notification => true, :events => ["#{tracker.name.downcase}_added"])

    ActionMailer::Base.deliveries.clear
    set_tmp_attachments_directory
    @request.session[:user_id] = 2

    with_settings :host_name => 'mydomain.foo', :protocol => 'http' do
      assert_difference 'Issue.count' do
        post :create, :project_id => 1,
          :issue => { :tracker_id => '1', :subject => 'With attachment' },
          :attachments => {'1' => {'file' => uploaded_test_file('testfile.txt', 'text/plain'), 'description' => 'test file'}}
      end
    end

    assert_not_nil ActionMailer::Base.deliveries.last
    assert_select_email do
      assert_select 'a[href^=?]', 'http://mydomain.foo/attachments/download', 'testfile.txt'
    end
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal 1, ActionMailer::Base.deliveries.last.bcc.length
    assert ActionMailer::Base.deliveries.last.bcc.include?('someone@foo.bar')
  end

  def test_put_update_without_custom_fields_param
    issue = Issue.find(1)
    project = issue.project

    m = project.members.last
    m.user.update_attributes(:mail_notification => 'selected')
    m.update_attributes(:mail_notification => true, :events => ["#{issue.tracker.name.downcase}_updated"])

    @request.session[:user_id] = 2
    ActionMailer::Base.deliveries.clear

    assert_equal '125', issue.custom_value_for(2).value
    old_subject = issue.subject
    new_subject = 'Subject modified by IssuesControllerTest#test_post_edit'

    assert_difference('Journal.count') do
      assert_difference('JournalDetail.count', 2) do
        put :update, :id => 1, :issue => {:subject => new_subject,
                                         :priority_id => '6',
                                         :category_id => '1' # no change
                                        }
      end
    end
    assert_redirected_to :action => 'show', :id => '1'
    issue.reload
    assert_equal new_subject, issue.subject
    # Make sure custom fields were not cleared
    assert_equal '125', issue.custom_value_for(2).value

    assert_equal 1, ActionMailer::Base.deliveries.size
    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    assert_equal 1, mail.bcc.length
    assert mail.bcc.include?('someone@foo.bar')
    assert mail.subject.starts_with?("[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}]")
    assert_mail_body_match "Subject changed from #{old_subject} to #{new_subject}", mail
  end

  def test_put_update_with_project_change
    issue = Issue.find(1)
    project = issue.project

    m = project.members.last
    m.user.update_attributes(:mail_notification => 'selected')

    events_available = ['issue_added' , 'issue_updated' , 'issue_note_added' ,
      'issue_status_updated' , 'issue_priority_updated', 'document_added' ,
      'file_added' , 'message_posted' , 'news_added' ,
      'news_comment_added' , 'wiki_content_added' , 'wiki_content_updated' ]

    events_to_update = []
    events_available.each do |e|
      if e.include?("issue_")
        project.trackers.each { |tracker|
          events_to_update << e.sub('issue') { tracker.name.downcase }
        }
      else
        events_to_update << e 
      end
    end
    m.update_attributes(:mail_notification => true, :events => events_to_update)
    issue.reload

    @request.session[:user_id] = 2
    ActionMailer::Base.deliveries.clear

    assert_difference('Journal.count') do
      assert_difference('JournalDetail.count', 3) do
        put :update, :id => 1, :issue => {:project_id => '2',
                                         :tracker_id => '1', # no change
                                         :priority_id => '6',
                                         :category_id => '3'
                                        }
      end
    end
    assert_redirected_to :action => 'show', :id => '1'
    issue = Issue.find(1)
    assert_equal 2, issue.project_id
    assert_equal 1, issue.tracker_id
    assert_equal 6, issue.priority_id
    assert_equal 3, issue.category_id

    mail = ActionMailer::Base.deliveries.last
    assert_nil mail
  end

  def test_put_update_with_tracker_change
    issue = Issue.find(1)
    tracker = Tracker.find(2)
    project = issue.project

    m = project.members.last
    m.user.update_attributes(:mail_notification => 'selected')
    m.update_attributes(:mail_notification => true, :events => ["#{tracker.name.downcase}_updated"])


    @request.session[:user_id] = 2
    ActionMailer::Base.deliveries.clear

    assert_difference('Journal.count') do
      assert_difference('JournalDetail.count', 2) do
        put :update, :id => 1, :issue => {:project_id => '1',
                                         :tracker_id => '2',
                                         :priority_id => '6'
                                        }
      end
    end
    assert_redirected_to :action => 'show', :id => '1'
    issue = Issue.find(1)
    assert_equal 1, issue.project_id
    assert_equal 2, issue.tracker_id
    assert_equal 6, issue.priority_id
    assert_equal 1, issue.category_id

    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    assert mail.subject.starts_with?("[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}]")
    assert_mail_body_match "Tracker changed from Bug to Feature request", mail
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal 1, ActionMailer::Base.deliveries.last.bcc.length
    assert ActionMailer::Base.deliveries.last.bcc.include?('someone@foo.bar')
  end

  def test_put_update_with_custom_field_change
    issue = Issue.find(1)
    project = issue.project

    m = project.members.last
    m.user.update_attributes(:mail_notification => 'selected')
    m.update_attributes(:mail_notification => true, :events => ["#{issue.tracker.name.downcase}_updated"])

    @request.session[:user_id] = 2
    issue = Issue.find(1)
    assert_equal '125', issue.custom_value_for(2).value

    assert_difference('Journal.count') do
      assert_difference('JournalDetail.count', 3) do
        put :update, :id => 1, :issue => {:subject => 'Custom field change',
                                         :priority_id => '6',
                                         :category_id => '1', # no change
                                         :custom_field_values => { '2' => 'New custom value' }
                                        }
      end
    end
    assert_redirected_to :action => 'show', :id => '1'
    issue.reload
    assert_equal 'New custom value', issue.custom_value_for(2).value

    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    assert_mail_body_match "Searchable field changed from 125 to New custom value", mail
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal 1, ActionMailer::Base.deliveries.last.bcc.length
    assert ActionMailer::Base.deliveries.last.bcc.include?('someone@foo.bar')
  end

  def test_put_update_with_status_and_assignee_change
    issue = Issue.find(1)
    project = issue.project

    m = project.members.last
    m.user.update_attributes(:mail_notification => 'selected')
    m.update_attributes(:mail_notification => true, :events => ["#{issue.tracker.name.downcase}_status_updated"])

    issue.reload

    issue = Issue.find(1)
    assert_equal 1, issue.status_id
    @request.session[:user_id] = 2
    assert_difference('TimeEntry.count', 0) do
      put :update,
           :id => 1,
           :issue => { :status_id => 2, :assigned_to_id => 3, :notes => 'Assigned to dlopper' },
           :time_entry => { :hours => '', :comments => '', :activity_id => TimeEntryActivity.first }
    end
    assert_redirected_to :action => 'show', :id => '1'
    issue.reload
    assert_equal 2, issue.status_id
    j = Journal.order('id DESC').first
    assert_equal 'Assigned to dlopper', j.notes
    assert_equal 2, j.details.size

    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    assert_mail_body_match "Status changed from New to Assigned", mail
    # subject should contain the new status
    assert mail.subject.include?("(#{ IssueStatus.find(2).name })")
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal 1, ActionMailer::Base.deliveries.last.bcc.length
    assert ActionMailer::Base.deliveries.last.bcc.include?('someone@foo.bar')
  end

  def test_put_update_with_note_only
    issue = Issue.find(1)
    project = issue.project

    m = project.members.last
    m.user.update_attributes(:mail_notification => 'selected')
    m.update_attributes(:mail_notification => true, :events => ["#{issue.tracker.name.downcase}_note_added"])

    notes = 'Note added by IssuesControllerTest#test_update_with_note_only'
    # anonymous user
    put :update,
         :id => 1,
         :issue => { :notes => notes }
    assert_redirected_to :action => 'show', :id => '1'
    j = Journal.order('id DESC').first
    assert_equal notes, j.notes
    assert_equal 0, j.details.size
    assert_equal User.anonymous, j.user

    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    assert_mail_body_match notes, mail
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal 1, ActionMailer::Base.deliveries.last.bcc.length
    assert ActionMailer::Base.deliveries.last.bcc.include?('someone@foo.bar')
  end

  # def test_put_update_with_attachment_only
  #   issue = Issue.find(1)
  #   project = issue.project

  #   m = project.members.last
  #   m.user.update_attributes(:mail_notification => 'selected')
  #   m.update_attributes(:mail_notification => true, :events => ["file_added"])

  #   set_tmp_attachments_directory

  #   # Delete all fixtured journals, a race condition can occur causing the wrong
  #   # journal to get fetched in the next find.
  #   Journal.delete_all
  #   ActionMailer::Base.deliveries.clear

  #   issue.reload
  #   # anonymous user
  #   assert_difference 'Attachment.count' do
  #     put :update, :id => 1,
  #       :issue => {:notes => ''},
  #       :attachments => {'1' => {'file' => uploaded_test_file('testfile.txt', 'text/plain'), 'description' => 'test file'}}
  #   end
  #   mail = ActionMailer::Base.deliveries.last
  #   assert_not_nil mail

  #   assert_redirected_to :action => 'show', :id => '1'
  #   j = Issue.find(1).journals.reorder('id DESC').first
  #   assert_equal 1, j.details.size
  #   assert_equal 'testfile.txt', j.details.first.value
  #   assert_equal User.anonymous, j.user

  #   attachment = Attachment.first(:order => 'id DESC')
  #   assert_equal Issue.find(1), attachment.container
  #   assert_equal User.anonymous, attachment.author
  #   assert_equal 'testfile.txt', attachment.filename
  #   assert_equal 'text/plain', attachment.content_type
  #   assert_equal 'test file', attachment.description
  #   assert_equal 61, attachment.filesize
  #   assert File.exists?(attachment.diskfile)
  #   assert_equal 61, File.size(attachment.diskfile)

  #   assert_mail_body_match 'testfile.txt', mail
  #   assert_equal 1, ActionMailer::Base.deliveries.size
  #   assert_equal 1, ActionMailer::Base.deliveries.last.bcc.length
  #   assert ActionMailer::Base.deliveries.last.bcc.include?('someone@foo.bar')
  # end

  # def test_put_update_with_priority_and_assignee_change
  #   issue = Issue.find(1)
  #   project = issue.project

  #   m = project.members.last
  #   m.user.update_attributes(:mail_notification => 'selected')
  #   m.update_attributes(:mail_notification => true, :events => ["#{issue.tracker.name.downcase}_priority_updated"])

  #   issue.reload
  #   ActionMailer::Base.deliveries.clear
    
  #   issue = Issue.find(1)
  #   assert_equal 1, issue.status_id
  #   @request.session[:user_id] = 2
  #   assert_difference('TimeEntry.count', 0) do
  #     put :update,
  #          :id => 1,
  #          :issue => { :status_id => 1, :assigned_to_id => 3, :notes => 'Assigned to dlopper' }, :priority_id => '6',
  #          :time_entry => { :hours => '', :comments => '', :activity_id => TimeEntryActivity.first }
  #   end
  #   mail = ActionMailer::Base.deliveries.last
  #   assert_not_nil mail

  #   assert_redirected_to :action => 'show', :id => '1'
  #   issue.reload
  #   assert_equal 1, issue.status_id
  #   j = Journal.order('id DESC').first
  #   assert_equal 'Assigned to dlopper', j.notes
  #   assert_equal 1, j.details.size
  #   assert_mail_body_match "Assignee set to Dave Lopper", mail
  #   assert_equal 1, ActionMailer::Base.deliveries.size
  #   assert_equal 1, ActionMailer::Base.deliveries.last.bcc.length
  #   assert ActionMailer::Base.deliveries.last.bcc.include?('someone@foo.bar')
  # end
end
