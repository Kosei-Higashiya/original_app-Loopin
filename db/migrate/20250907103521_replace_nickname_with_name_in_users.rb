class ReplaceNicknameWithNameInUsers < ActiveRecord::Migration[7.1]
  def change
    remove_column :users, :nickname, :string
    add_column :users, :name, :string
  end
end