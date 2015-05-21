module EventNotification
  module Patches
    module JournalPatch

      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
          before_save         :set_issue_updated_options
          alias_method_chain  :notified_users, :events
        end
      end

      module InstanceMethods
        def only_attachments
          @only_attachments ||= false
        end

        def only_relations
          @only_relations ||= false
        end

        def set_issue_updated_options
          # During issue update, Check if journal is only about relation added or Attachment added.
          return unless notes.blank?
          return unless details.any?
          logger.debug("Contains details.")
          attachment_cnt  = 0
          relation_cnt    = 0
          details.each do |detail|
            return if !%w(attachment relation).include?(detail.property)
            attachment_cnt += 1 if detail.property == 'attachment'
            relation_cnt   += 1 if detail.property == 'relation' && !detail.prop_key.starts_with?("block")
          end
          # Assume that relation and attachment cannot be added at the same time.
          @only_attachments = details.length == attachment_cnt  ? true : false
          @only_relations   = details.length == relation_cnt    ? true : false
          logger.debug("Set variable for Journal : Attachment or Relations.")
        end

        def notified_users_with_events
          return [] if User.current.ghost?
          if Setting.plugin_event_notifications["enable_event_notifications"] == "on"
            logger.debug("Notified Users : Select users.")

            notified = journalized.notified_users
            notified += journalized.project.notified_users(self)
            notified = notified.select {|u| u.active?}
            notified.uniq!
            if private_notes?
              notified = notified.select {|user| user.allowed_to?(:view_private_notes, journalized.project)}
            end
            notified
          else
            notified_users_without_events
          end
        end
      end
    end
  end
end

unless Journal.included_modules.include? EventNotification::Patches::JournalPatch
  Journal.send(:include, EventNotification::Patches::JournalPatch)
end
