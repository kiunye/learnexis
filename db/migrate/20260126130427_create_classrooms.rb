class CreateClassrooms < ActiveRecord::Migration[8.1]
  def change
    create_table :classrooms do |t|
      t.string :name
      t.integer :grade_level
      t.string :section
      t.integer :academic_year
      t.integer :capacity
      t.string :room_number
      t.references :class_teacher, null: true, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :classrooms, [ :name, :academic_year ], unique: true
    add_index :classrooms, :grade_level
  end
end
