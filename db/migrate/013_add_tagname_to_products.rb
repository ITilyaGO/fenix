class AddTagnameToProducts < ActiveRecord::Migration
  def change
    add_column :products, :tagname, :string
  end
end