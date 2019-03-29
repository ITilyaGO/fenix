class AddContractToClients < ActiveRecord::Migration
  def change
    add_column :clients, :contract, :string
  end
end