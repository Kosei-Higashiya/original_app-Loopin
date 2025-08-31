class CreateHabitRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :habit_records do |t|
      t.string :title, null: false
      t.text :content
      t.references :user, null: false, foreign_key: true
      t.boolean :is_public, default: true
      t.date :recorded_at, default: -> { 'CURRENT_DATE' }

      t.timestamps
    end

    add_index :habit_records, :user_id
    add_index :habit_records, :is_public
    add_index :habit_records, :recorded_at
  end
end