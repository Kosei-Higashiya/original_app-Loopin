class AddOmniauthToUsers < ActiveRecord::Migration[7.2]
  def change
    change_table :users, bulk: true do |t|
      t.string :provider
      t.string :uid
    end

    add_index :users, %i[provider uid], unique: true
  end
end
