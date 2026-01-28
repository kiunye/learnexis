class CreateAttendances < ActiveRecord::Migration[8.1]
  def change
    create_table :attendances do |t|
      t.references :student, null: false, foreign_key: true
      t.references :classroom, null: false, foreign_key: true
      t.date :attendance_date, null: false
      t.integer :status, default: 0, null: false
      t.text :remarks
      t.datetime :marked_at
      t.references :marked_by, null: true, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :attendances, [ :student_id, :attendance_date ], unique: true
    add_index :attendances, [ :classroom_id, :attendance_date ]
    add_index :attendances, :attendance_date
  end
end
