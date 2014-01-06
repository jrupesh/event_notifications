class AddEventColToMembers < ActiveRecord::Migration
  def change
	  add_column :members, :events, :text
  end
end
