# frozen_string_literal: true

class AddTransportRouteToStudents < ActiveRecord::Migration[8.1]
  def change
    add_reference :students, :transport_route, null: true, foreign_key: true
  end
end
