class CreateHabitRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :habit_records do |t|
      t.references :user, null: false, foreign_key: true
      t.references :habit, null: false, foreign_key: true
      t.date :recorded_at
      t.text :note
      t.string :image
      t.boolean :completed, default: true, null: false

      t.timestamps
    end

    add_index :habit_records, %i[user_id habit_id recorded_at], unique: true,
                                                                name: 'index_habit_records_on_user_habit_date'
    add_index :habit_records, :recorded_at
    add_index :habit_records, :completed
  end
end
