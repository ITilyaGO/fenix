class AddParentToProducts < ActiveRecord::Migration
  def change
    add_column :products, :parent_id, :integer
  end
end