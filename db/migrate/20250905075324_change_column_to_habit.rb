class ChangeColumnToHabit < ActiveRecord::Migration[7.1]
  def change
    remove_column :habits, :active, :boolean
    remove_index :habits, column: :active, if_exists: true
  end
end
