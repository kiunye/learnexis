class CreateFees < ActiveRecord::Migration[8.1]
  def change
    create_table :fees do |t|
      t.string :name, null: false
      t.integer :fee_type, null: false, default: 0
      t.decimal :amount, precision: 12, scale: 2, null: false, default: 0
      t.integer :academic_year, null: false
      t.integer :status, null: false, default: 0
      t.date :due_date

      t.timestamps
    end

    add_index :fees, [ :academic_year, :fee_type ]
  end
end
