**Event Notifications**
========

Description:
--------

In the Redmine notifications, The notifications can be enabled at the global level of the project.
This plugin allows the capabilty to add notifications at each event of the project.
Events available at the project.
'issue_added', 'issue_updated', 'issue_note_added', 'issue_status_updated', 'issue_priority_updated', 'document_added', 'message_posted', 'news_added', 'news_comment_added', 'wiki_content_added', 'wiki_content_updated'

* This plugin further enhances the redmine notifications at the issue level based on the tracker type.

* This plugin allows the user to be notified based on the field value of a Custom field or a Issue Category.

* Also provides additional powerful feature to enable the user to be notified whenever a involved issue has some changes.
** EX: This is a crude example, In our org we have specific relation for this notificaiton.
** When a issue has a specific relation ( Say : A Follows B ) and the user has opted to be notified for the involed issue notified and is the author of issue B.
** Whenever issue A is updated, Automatically author, Assignee of B will be notified of the ticket change done in A.

* Additionally, Provides option to disable notiifcation on a custom field change.
** Generally, there are some fields which are meant for data quality on which the user need not be notified. Such fields can be disabled of notification.

  ![Custom Field Notification](/custom_field_option.jpg "Custom Field Disable notification.")


* Allow Admins to update tickets in Ghost mode.
** This allows the admin to mass update tickets without notifiying users not journalizing tickets of these changes.

  ![User Preference - Admin](/user_pref.jpg "Adming Ghost Mode Options")

* Specify the mail delivery from user.
** Can be from Redmine user, or the user making the changes.

  ![Notification Options](/notification_options.jpg "Event Notification Mailer Options")


* Disable notification of tickets when a attachements are added / removed. A relation is added / removed. ( Except Blocks / Blocked By relatiosn )

Installation procedure:
--------

* Follow the default plugin installation procedure of redmine.

* Login as admin, Enable the plugin event notification settings.

	![Admin plugin settings](/enable_event_notification.jpg "Event Notification")

* Now for all the users, The project events notification is enabled.

  ![User account settings](/project_events.jpg "User Event Notification Settings")

* Additional Options :

  ![Advance settings](/advance_settings.jpg "Advance Event Notification Settings")