class CreateTeacherProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :teacher_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :employee_number
      t.string :department

      t.timestamps
    end

    add_index :teacher_profiles, :employee_number, unique: true
  end
end
