class CreateTimelineSections < ActiveRecord::Migration
  def self.up
    create_table :timeline_sections do |t|
      t.integer :order_id
      t.integer :section_id
      t.integer :weekday
      t.timestamps
    end
  end

  def self.down
    drop_table :timeline_sections
  end
end