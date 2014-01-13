module Patches
  module MemberPatch

    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable
        serialize :events
      end
    end

    module InstanceMethods
    end

    module ClassMethods
      def update_events!
        #Update all the events with respect to the project notifications.
        events_available = Setting.notified_events
        #Project 
        Project.all.each do |p|
          events_to_update = []
          events_available.each do |e|
            if e.include?("issue_")
              p.trackers.each { |tracker|
                events_to_update << e.sub('issue') { tracker.name.downcase }
              }
            else
              events_to_update << e 
            end
          end

          members = p.members.select {|m| m.principal.present? && 
            (m.mail_notification? || m.principal.mail_notification == 'all')}

          Member.where(:project_id => [p.id]).update_all(:mail_notification => false, :events => [])
          members.each { |m| m.update_attributes(:mail_notification => true, :events => events_to_update) }
        end
      end
    end
  end
end

Member.send(:include, Patches::MemberPatch)
