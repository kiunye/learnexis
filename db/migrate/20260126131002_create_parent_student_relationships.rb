class CreateParentStudentRelationships < ActiveRecord::Migration[8.1]
  def change
    create_table :parent_student_relationships do |t|
      t.references :parent, null: false, foreign_key: { to_table: :users }
      t.references :student, null: false, foreign_key: true
      t.string :relationship_type, default: "parent"

      t.timestamps
    end

    add_index :parent_student_relationships, [ :parent_id, :student_id ], unique: true, name: "index_parent_student_relationships_on_parent_and_student"
  end
end
