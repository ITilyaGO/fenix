class AddMinOrderToProducts < ActiveRecord::Migration
  def change
    add_column :products, :min_order, :integer
  end
end