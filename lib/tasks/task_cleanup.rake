namespace :notification do

  desc  <<-END_DESC
Removes all the updated tasks as the issue_updated event is not active, Issue with the migration.
Example:
  rake notification:cleanup RAILS_ENV="production"
END_DESC
  task :cleanup => :environment do
    unless Setting.notified_events.include?("issue_updated")
      trackers = Tracker.all.to_a.collect{ |t| "issue_updated".sub("issue"){t.name.downcase}.gsub(" ","_")}
      Member.find_in_batches(batch_size: 1000, start: startval ) do |batch|
        batch.each do |m|
          next if m.events.nil? || !(trackers.any? { |e|  m.events.include?(e) })
          # TO DO : Cleanup if they updated tasks any ?
        end
      end
    end
  end
end