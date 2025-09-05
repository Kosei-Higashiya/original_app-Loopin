class RemoveActiveFromHabits < ActiveRecord::Migration[7.1]
  def change
    remove_column :habits, :active, :boolean
    remove_index :habits, name: "index_habits_on_active" if index_exists?(:habits, :active)
  end
end