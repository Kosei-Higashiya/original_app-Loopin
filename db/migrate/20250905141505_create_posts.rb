class CreatePosts < ActiveRecord::Migration[7.1]
  def change
    create_table :posts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :habit, null: false, foreign_key: true
      t.text :content
      t.string :image

      t.timestamps
    end

    add_index :posts, :created_at
    add_index :posts, [:user_id, :created_at]
  end
end
