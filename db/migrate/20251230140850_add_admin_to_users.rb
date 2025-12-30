class AddAdminToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :admin, :boolean
    add_index :users, :admin
  end
end
