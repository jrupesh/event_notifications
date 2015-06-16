module EventNotification
  module Patches
    module IssuePatch

      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable

          before_save :set_new_issue_record
          alias_method_chain :notified_users, :events
          alias_method_chain :create_journal, :ghost
        end
      end

      module InstanceMethods
        def create_journal_with_ghost
          return unless !User.current.ghost?
          create_journal_without_ghost
        end

        def set_new_issue_record
          @set_issue_record = new_record? ? 1 : 0
        end

        def is_issue_new_record?
          @set_issue_record ||= 0
        end

        def collect_related_issues
          # collect father, child and brother issues
          issues = [self]
          self.relations.each do |relation|
            other_issue = relation.other_issue(self)
            relation_type = relation.relation_type_for(self)
            issues << other_issue if relation_type == IssueRelation::TYPE_IMPLEMENTED
            if relation_type == IssueRelation::TYPE_IMPLEMENTS
              father_issue = other_issue
              father_issue.relations.each do |father_issue_relation|
                father_other_issue = father_issue_relation.other_issue(father_issue)
                father_relation_type = father_issue_relation.relation_type_for(father_issue)
                issues << father_other_issue if father_relation_type == IssueRelation::TYPE_IMPLEMENTED
              end
            end
          end
          issues.uniq!
        end

        def collect_involved_related_users
          notified = []
          if Setting.plugin_event_notifications["issue_involved_in_related_notified"] == "on"
            # Author and assignee are always notified unless they have been locked or have refused that
            custom_field_users = []

            issues = collect_related_issues

            return notified unless !issues.nil?

            issues.each do |issue|
              next if issue == self

              if issue.author && issue.author.active? && %w( all selected ).include?( issue.author.mail_notification )
                notified << issue.author if issue.author.pref[:involved_in_related_notified] == '1'
              end

              if issue.assigned_to && issue.assigned_to.active? && %w( all selected ).include?( issue.author.mail_notification )
                notified << issue.assigned_to if issue.assigned_to.pref[:involved_in_related_notified] == '1'
              end

              issue.custom_values.each do |cv|
                next if cv.custom_field.field_format != 'user'
                custom_field_users << cv.value.to_i unless cv.value.nil?
              end
            end
            notified += User.where(:id => custom_field_users).select { |u| u.pref[:involved_in_related_notified] == '1' } if custom_field_users.any?
          end
          notified
        end

        def notified_users_with_events
          return [] if User.current.ghost? || User.get_notification == false
          if Setting.plugin_event_notifications["enable_event_notifications"] == "on"
            notified = []
            # Author and assignee are always notified unless they have been
            # locked or don't want to be notified
            notified << author if author
            if assigned_to
              notified += (assigned_to.is_a?(Group) ? assigned_to.users : [assigned_to])
            end
            if assigned_to_was
              notified += (assigned_to_was.is_a?(Group) ? assigned_to_was.users : [assigned_to_was])
            end
            notified += collect_involved_related_users

            notified =   notified.select {|u| u.active? && u.notify_about?(self)}
            notified +=  project.notified_users_with_events(self)

            notified.uniq!
            # Remove users that can not view the issue
            notified.reject! {|user| !visible?(user)}
            notified
          else
            notified_users_without_events
          end
        end
      end
    end
  end
end

unless Issue.included_modules.include? EventNotification::Patches::IssuePatch
  Issue.send(:include, EventNotification::Patches::IssuePatch)
end
