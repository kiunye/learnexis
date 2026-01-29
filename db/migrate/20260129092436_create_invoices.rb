class CreateInvoices < ActiveRecord::Migration[8.1]
  def change
    create_table :invoices do |t|
      t.references :student, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.date :issue_date, null: false
      t.date :due_date, null: false
      t.decimal :total_amount, precision: 12, scale: 2, null: false, default: 0
      t.text :notes

      t.timestamps
    end

    add_index :invoices, :status
    add_index :invoices, [ :student_id, :issue_date ]
  end
end
