require 'csv'
namespace :notification do
  desc  <<-END_DESC
Removes all the updated tasks as the issue_updated event is not active, Issue with the migration.
Example:
  rake notification:update user=allusers RAILS_ENV="production"
END_DESC
  task :update => :environment do

    dir = ENV['DIR'] || './tmp/test'

    env_user   = ENV['user'] || nil

    if !env_user.nil? && env_user != 'allusers'
      export_user = User.find_by_login(env_user.dup)
      abort("User login does not exist.") if export_user.nil?
      user_list = [export_user]
    else
      puts "Running rake for all users."
      user_list = User.all.status(1)
    end

    trackers = {}
    Tracker.all.each { |t| trackers.merge!({t.id => t}) }

    user_list.each do |user|
      file = File.join(dir,"#{user.login}.csv")
      next if !File.exist?(file)
      puts "Updating notification for #{user.name} from #{file}."

      memberships = {}
      user.memberships.each{ |m| memberships.merge!({ m.project_id => m })   }

      arr_of_arrs = CSV.read( file )

      arr_of_arrs.each do |csv_line|
        if csv_line[0] == "pref"
          # [ "pref",user.pref.time_zone, user.pref.comments_sorting, user.pref[:landing_page], user.pref[:involved_in_related_notified] ]
          user.pref.time_zone                     = csv_line[1] if !csv_line[1].nil?
          user.pref.comments_sorting              = csv_line[2] if !csv_line[2].nil?
          user.pref.landing_page                  = "o-#{csv_line[3]}" if !csv_line[3].nil?
          user.pref.involved_in_related_notified  = csv_line[4] == 'TRUE' if !csv_line[4].nil?
        elsif csv_line[0] == "user"
          if csv_line[1] == 'FALSE'
            user.mail_notification = 'none'
          else
            user.mail_notification = "selected"
          end
        else
          m = !csv_line[1].nil? ? memberships[csv_line[1].to_i] : nil
          if !m.nil?
            if csv_line[2].starts_with?('issue') && !csv_line[3].nil?
              tracker = trackers[csv_line[3].to_i]
              next if !events.nl? && events.include?("CF")
              m.events << csv_line[2].dup.sub('issue') { tracker.name.downcase } if !tracker.nil?
            elsif csv_line[2].starts_with?('message_post') && !csv_line[4].nil?
              m.events << "#{csv_line[2]}-board-#{csv_line[4]}"
            else
              m.events << csv_line[2].dup
            end
          else
            puts "Event null for #{user.login} project #{csv_line[1]} value #{csv_line[2]}"
          end
        end
      end

      user.save
      memberships.each do |id, m|
        m.events.uniq!
        m.mail_notification = m.events.length > 0 ? true : false
        m.save
        Rails.logger.debug("Membership for #{user.id} : #{m.project_id} #{m.events}")
      end
    end
  end
end