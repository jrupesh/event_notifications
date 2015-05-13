module Patches
  module WatchersControllerPatch

    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable
      end
    end

    module InstanceMethods
      def preview_watchers
        @issue = Issue.find(params[:id]) if @issue.nil? & params[:id].present?
        if !@issue.nil?
          @project = @issue.project
        else
          render_403 :message => :notice_issue_not_found 
          return
        end

        respond_to do |format|
          format.js do        
          end
        end
      end
    end
  end
end

WatchersController.send(:include, Patches::WatchersControllerPatch)