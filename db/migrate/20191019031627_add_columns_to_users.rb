class AddColumnsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :former_district_hospital_id, :integer
    add_column :users, :from_mis_app, :boolean, default: false
  end

  def self.down
    remove_column :users, :former_district_hospital_id
    remove_column :users, :from_mis_app
  end
end
