class CreateBuses < ActiveRecord::Migration[8.1]
  def change
    create_table :buses do |t|
      t.string :bus_number
      t.string :registration_number
      t.integer :capacity
      t.string :driver_name
      t.string :driver_phone
      t.string :driver_license_number
      t.date :insurance_expiry
      t.date :last_maintenance_date
      t.date :next_maintenance_date
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
