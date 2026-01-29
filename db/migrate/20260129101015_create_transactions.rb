class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.references :invoice, null: true, foreign_key: true
      t.references :student, null: false, foreign_key: true
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.integer :payment_method, null: false, default: 0
      t.integer :transaction_type, null: false, default: 0
      t.date :transaction_date, null: false
      t.string :reference
      t.text :notes
      t.references :recorded_by, null: true, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :transactions, :transaction_date
    add_index :transactions, :payment_method
  end
end
