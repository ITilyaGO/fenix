class CreateRoundtrips < ActiveRecord::Migration
  def self.up
    create_table :roundtrips do |t|
      t.datetime :start_at
      t.integer :place_id
      t.timestamps
    end
  end

  def self.down
    drop_table :roundtrips
  end
end