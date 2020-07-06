class ChangeOrderPartBoxes < ActiveRecord::Migration
  def up
    change_column :order_parts, :boxes, :integer, default: nil
  end

  def down
    change_column :order_parts, :boxes, :integer, default: 0
  end
end