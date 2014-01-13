class AddEventColToMembers < ActiveRecord::Migration
  def change
	  add_column :members, :events, :text
	  Member.update_events!
  end
end
