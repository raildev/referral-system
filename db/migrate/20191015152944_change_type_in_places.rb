class ChangeTypeInPlaces < ActiveRecord::Migration
  def self.up
    change_column :places, :type, :string, :limit => 55
    add_column :places, :from_mis_app, :boolean, default: false
  end

end
