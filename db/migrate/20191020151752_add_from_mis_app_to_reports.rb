class AddFromMisAppToReports < ActiveRecord::Migration
  def self.up
    add_column :reports, :from_mis_app, :boolean, default: false
  end

  def self.down
    remove_column :reports, :from_mis_app
  end
end
