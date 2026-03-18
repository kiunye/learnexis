class CreateTransportRoutes < ActiveRecord::Migration[8.1]
  def change
    create_table :transport_routes do |t|
      t.string :name
      t.string :route_code
      t.string :area
      t.text :stops
      t.decimal :distance_km
      t.decimal :monthly_fee
      t.time :pickup_time
      t.time :dropoff_time
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :transport_routes, :route_code, unique: true
    add_index :transport_routes, :area
  end
end
