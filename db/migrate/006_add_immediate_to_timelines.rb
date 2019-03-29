class AddImmediateToTimelines < ActiveRecord::Migration
  def change
    add_column :timelines, :immediate, :boolean, :default => true
  end
end