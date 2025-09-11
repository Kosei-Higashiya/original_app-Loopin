class CreateBadges < ActiveRecord::Migration[7.1]
  def change
    create_table :badges do |t|
      t.string :name, null: false
      t.text :description
      t.string :icon
      t.string :condition_type, null: false
      t.integer :condition_value
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :badges, :name, unique: true
    add_index :badges, :condition_type
    add_index :badges, :active
  end
end