class AddManagerToClients < ActiveRecord::Migration
  def change
    add_column :clients, :manager_id, :integer, default: nil
  end
end