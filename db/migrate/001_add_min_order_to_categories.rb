class AddMinOrderToCategories < ActiveRecord::Migration
  def change
    add_column :categories, :min_order, :integer, :default => 10
  end
end