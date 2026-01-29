class CreateFeeAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :fee_assignments do |t|
      t.references :fee, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: true
      t.decimal :amount_override, precision: 12, scale: 2
      t.decimal :discount_percent, precision: 5, scale: 2, default: 0
      t.decimal :discount_amount, precision: 12, scale: 2, default: 0
      t.boolean :exempt, null: false, default: false
      t.integer :installment_count, default: 1
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :fee_assignments, [ :fee_id, :student_id ], unique: true
  end
end
