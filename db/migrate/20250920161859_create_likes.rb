class CreateLikes < ActiveRecord::Migration[7.1]
  def change
    create_table :likes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true

      t.timestamps
    end

    # 一つのユーザーは同じ投稿に対して一度だけいいねできる
    add_index :likes, %i[user_id post_id], unique: true
  end
end
