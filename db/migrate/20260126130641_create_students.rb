class CreateStudents < ActiveRecord::Migration[8.1]
  def change
    create_table :students do |t|
      t.string :admission_number
      t.date :date_of_birth
      t.date :admission_date
      t.integer :status, default: 0
      t.text :medical_conditions
      t.text :allergies
      t.text :special_needs
      t.string :emergency_contact_name
      t.string :emergency_contact_phone
      t.string :blood_group
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.references :classroom, null: true, foreign_key: true

      t.timestamps
    end

    add_index :students, :admission_number, unique: true
    add_index :students, :status
  end
end
