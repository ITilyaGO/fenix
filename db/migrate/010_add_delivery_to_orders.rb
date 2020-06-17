class AddDeliveryToOrders < ActiveRecord::Migration
  class Order < ActiveRecord::Base
  end

  def change
    add_column :orders, :delivery, :integer, default: 0
    reversible do |dir|
      dir.up { Order.where(moscow: true).update_all delivery: 3 }
    end
  end
end