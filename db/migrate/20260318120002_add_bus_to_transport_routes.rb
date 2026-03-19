# frozen_string_literal: true

class AddBusToTransportRoutes < ActiveRecord::Migration[8.1]
  def change
    add_reference :transport_routes, :bus, null: true, foreign_key: true
  end
end
