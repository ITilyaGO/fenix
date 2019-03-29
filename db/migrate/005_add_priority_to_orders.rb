class AddPriorityToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :priority, :boolean, :default => false
  end
end
