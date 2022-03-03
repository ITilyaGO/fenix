class ChangeOrderLineProduct < ActiveRecord::Migration
  def up
    change_column :order_lines, :product_id, :string
  end

  def down
    change_column :order_lines, :product_id, :integer
  end
end