class AddProjectFormatStore < ActiveRecord::Migration
  def change
    unless column_exists? :projects, :format_store
      add_column :projects, :format_store, :text 
    end
  end
end