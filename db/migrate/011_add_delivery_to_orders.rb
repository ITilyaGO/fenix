class AddDeliveryToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :delivery, :integer, :default => 0
  end
end