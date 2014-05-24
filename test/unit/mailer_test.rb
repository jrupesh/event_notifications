require File.expand_path('../../test_helper', __FILE__)

class ActiveSupport::TestCase

  def setup_with_global
    Setting.plugin_event_notifications["enable_event_notifications"] = "on"
    ActionMailer::Base.deliveries.clear
    Setting.host_name = 'mydomain.foo'
    Setting.protocol = 'http'
    Setting.plain_text_mail = '0'

    role = Role.find(2)
    user = User.find(7)
    project = Project.find(1)
    Member.create!(:principal => user, :project => project, :roles => [role])

    Member.update_all(:mail_notification => false, :events => [])
    User.update_all(:mail_notification => 'none')

    setup_without_global
  end

  alias_method_chain :setup, :global
end

class MailerTest < ActiveSupport::TestCase
  include Redmine::I18n
  include ActionDispatch::Assertions::SelectorAssertions
  fixtures :projects, :enabled_modules, :issues, :users, :members,
           :member_roles, :roles, :documents, :attachments, :news,
           :tokens, :journals, :journal_details, :changesets,
           :trackers, :projects_trackers,
           :issue_statuses, :enumerations, :messages, :boards, :repositories,
           :wikis, :wiki_pages, :wiki_contents,
           :versions,
           :comments

  def last_email
    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    mail
  end

  test "tracker_add_issue should notify project members" do
    issue = Issue.create!(:project_id => 1, :tracker_id => 1, :author_id => 3,
                  :status_id => 1, :priority => IssuePriority.all.first,
                  :subject => 'test_create')
    m = issue.project.members.last
    m.user.update_attributes(:mail_notification => 'selected')
    m.update_attributes(:mail_notification => true, :events => ["#{issue.tracker.name.downcase}_added"])
    issue.reload

    assert Mailer.deliver_issue_add(issue)
    mail = last_email
    assert mail.bcc.include?('someone@foo.bar')
    assert_equal mail.bcc.length, 1
  end

  test "tracker_update_issue should notify project members" do
    issue = Issue.first
    user = User.first
    m = issue.project.members.last
    m.user.update_attributes(:mail_notification => 'selected')
    m.update_attributes(:mail_notification => true, :events => ["#{issue.tracker.name.downcase}_updated"])

    journal = issue.init_journal(user, issue)
    journal.save! 
    journal.reload

    Mailer.deliver_issue_edit(journal)
    mail = last_email
    assert mail.bcc.include?('someone@foo.bar')
    assert_equal mail.bcc.length, 1
  end

  test "document_added should notify project members" do
    document = Document.find(1)
    m = document.project.members.last
    m.user.update_attributes(:mail_notification => 'selected')
    m.update_attributes(:mail_notification => true, :events => ["document_added"])
    document.reload

    Mailer.document_added(document).deliver
    mail = last_email
    assert mail.bcc.include?('someone@foo.bar')
    assert_equal mail.bcc.length, 1
  end

  test "issue_note_added should notify project members" do

    issue = Issue.first
    user = User.first
    m = issue.project.members.last
    m.user.update_attributes(:mail_notification => 'selected')
    m.update_attributes(:mail_notification => true, :events => ["#{issue.tracker.name.downcase}_note_added"])

    journal = issue.init_journal(user, issue)
    journal.save! 
    journal.reload

    Mailer.deliver_issue_edit(journal)
    mail = last_email
    assert mail.bcc.include?('someone@foo.bar')
    assert_equal mail.bcc.length, 1
  end

  test "issue_status_updated should notify project members" do

    journal = Journal.find 1
    issue = journal.journalized

    m = issue.project.members.last
    m.user.update_attributes(:mail_notification => 'selected')
    m.update_attributes(:mail_notification => true, :events => ["#{issue.tracker.name.downcase}_status_updated"])

    journal.notes = ""
    journal.new_status
    journal.save! 
    journal.reload

    Mailer.deliver_issue_edit(journal)
    mail = last_email
    assert mail.bcc.include?('someone@foo.bar')
    assert_equal mail.bcc.length, 1
  end

  test "issue_priority_updated should notify project members" do

    issue = Issue.first
    d = JournalDetail.create!(:property => "attr", :prop_key => 'priority_id', 
          :old_value => IssuePriority.find(4), :value => IssuePriority.find(5))

    journal = Journal.create!(:details => [d], :journalized => issue)

    m = issue.project.members.last
    m.user.update_attributes(:mail_notification => 'selected')
    m.update_attributes(:mail_notification => true, :events => ["#{issue.tracker.name.downcase}_priority_updated"])

    journal.reload
    issue.reload

    Mailer.deliver_issue_edit(journal)
    mail = last_email
    assert mail.bcc.include?('someone@foo.bar')
    assert_equal mail.bcc.length, 1
  end

  test "message_posted should notify project members" do
    message = Message.find(1)
    m = message.project.members.last
    m.user.update_attributes(:mail_notification => 'selected')
    m.update_attributes(:mail_notification => true, :events => ["message_posted"])
    message.reload

    Mailer.message_posted(message).deliver

    mail = last_email
    assert mail.bcc.include?('someone@foo.bar')
    assert_equal mail.bcc.length, 1
  end

  test "news_added should notify project members" do
    news = News.find(2)
    m = news.project.members.last
    m.user.update_attributes(:mail_notification => 'selected')
    m.update_attributes(:mail_notification => true, :events => ["news_added"])
    news.reload

    Mailer.news_added(news).deliver

    mail = last_email
    assert mail.bcc.include?('someone@foo.bar')
    assert_equal mail.bcc.length, 1
  end

  test "news_comment_added should notify project members" do
    comment = Comment.find(1)
    m = comment.commented.project.members.last
    m.user.update_attributes(:mail_notification => 'selected')
    m.update_attributes(:mail_notification => true, :events => ["news_comment_added"])
    comment.reload

    Mailer.news_comment_added(comment).deliver

    mail = last_email
    assert mail.bcc.include?('someone@foo.bar')
    assert_equal mail.bcc.length, 1
  end

  test "wiki_content_added should notify project members" do
    wikicontent = WikiContent.find(2)
    m = wikicontent.page.wiki.project.members.last
    m.user.update_attributes(:mail_notification => 'selected')
    m.update_attributes(:mail_notification => true, :events => ["wiki_content_added"])
    wikicontent.reload

    Mailer.wiki_content_added(wikicontent).deliver

    mail = last_email
    assert mail.bcc.include?('someone@foo.bar')
    assert_equal mail.bcc.length, 1
  end

  test "wiki_content_updated should notify project members" do
    wikicontent = WikiContent.find(1)
    m = wikicontent.page.wiki.project.members.last
    m.user.update_attributes(:mail_notification => 'selected')
    m.update_attributes(:mail_notification => true, :events => ["wiki_content_updated"])
    wikicontent.reload

    Mailer.wiki_content_added(wikicontent).deliver

    mail = last_email
    assert mail.bcc.include?('someone@foo.bar')
    assert_equal mail.bcc.length, 1
  end

  test "tracker_add_issue should not notify project members" do
    issue = Issue.create!(:project_id => 1, :tracker_id => 1, :author_id => 3,
                  :status_id => 1, :priority => IssuePriority.all.first,
                  :subject => 'test_create')
    issue.reload
    User.set_notification(false)
    assert !Mailer.deliver_issue_add(issue)

    mail = ActionMailer::Base.deliveries.last
    assert_nil mail

    User.set_notification(true)

    issue.reload
    m = issue.project.members.last
    m.user.update_attributes(:mail_notification => 'selected')
    m.update_attributes(:mail_notification => true, :events => ["#{issue.tracker.name.downcase}_added"])

    assert Mailer.deliver_issue_add(issue)

    mail = last_email
    assert mail.bcc.include?('someone@foo.bar')
    assert_equal mail.bcc.length, 1
  end  
end

