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

class DocumentsControllerTest < ActionController::TestCase
  fixtures :projects, :users, :roles, :members, :member_roles,
           :enabled_modules, :documents, :enumerations,
           :groups_users, :attachments

  def setup
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
    ActionMailer::Base.deliveries.clear
  end

  def test_create_with_one_attachment
    project = Project.find_by_name("ecookbook")
    m = project.members.last
    m.user.update_attributes(:mail_notification => 'selected')
    m.update_attributes(:mail_notification => true, :events => ["document_added"])

    ActionMailer::Base.deliveries.clear
    @request.session[:user_id] = 2
    set_tmp_attachments_directory

    with_settings :notified_events => %w(document_added) do
      post :create, :project_id => 'ecookbook',
               :document => { :title => 'DocumentsControllerTest#test_post_new',
                              :description => 'This is a new document',
                              :category_id => 2},
               :attachments => {'1' => {'file' => uploaded_test_file('testfile.txt', 'text/plain')}}
    end
    assert_redirected_to '/projects/ecookbook/documents'

    document = Document.find_by_title('DocumentsControllerTest#test_post_new')
    assert_not_nil document
    assert_equal Enumeration.find(2), document.category
    assert_equal 1, document.attachments.size
    assert_equal 'testfile.txt', document.attachments.first.filename
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert ActionMailer::Base.deliveries.last.bcc.include?('someone@foo.bar')
  end
end