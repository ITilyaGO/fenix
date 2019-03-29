class AddShippingCompanyToClients < ActiveRecord::Migration
  def change
    add_column :clients, :shipping_company, :string
  end
end