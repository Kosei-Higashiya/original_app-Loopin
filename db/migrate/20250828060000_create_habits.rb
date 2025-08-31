class CreateHabits < ActiveRecord::Migration[7.1]
  def change
    create_table :habits do |t|
      t.string :title, null: false
      t.text :description
      t.references :user, null: false, foreign_key: true
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :habits, :user_id
    add_index :habits, :active
  end
end