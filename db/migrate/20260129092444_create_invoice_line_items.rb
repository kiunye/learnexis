class CreateInvoiceLineItems < ActiveRecord::Migration[8.1]
  def change
    create_table :invoice_line_items do |t|
      t.references :invoice, null: false, foreign_key: true
      t.references :fee_assignment, null: true, foreign_key: true
      t.string :description, null: false, default: ""
      t.integer :quantity, null: false, default: 1
      t.decimal :unit_amount, precision: 12, scale: 2, null: false, default: 0
      t.decimal :amount, precision: 12, scale: 2, null: false, default: 0

      t.timestamps
    end
  end
end
