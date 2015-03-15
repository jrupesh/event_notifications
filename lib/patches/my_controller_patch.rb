module Patches
  module MyControllerPatch

    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development
        before_filter :account_patch, :only => :account
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      # Edit user's account - PATCH
      def account_patch
        @user = User.current
        @pref = @user.pref
        if request.post?
          @user.safe_attributes = params[:user]
          @user.pref.attributes = params[:pref]
          if @user.save
            @user.pref.save
            @user.notify_events= (params[:user]["mail_notification"] == 'selected' ? params[:user]["notified_project_ids"] : [])
            set_language_if_valid @user.language
            flash[:notice] = l(:notice_account_updated)
            redirect_to my_account_path
            return
          end
        end
      end
    end
  end
end
MyController.send(:include, Patches::MyControllerPatch)