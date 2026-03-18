class Bus < ApplicationRecord
  # Associations
  has_many :transport_routes
  has_many :students, through: :transport_routes

  # Validations
  validates :bus_number, :registration_number, presence: true, uniqueness: true
  validates :capacity, presence: true, numericality: { greater_than: 0 }
  validates :driver_name, :driver_phone, :driver_license_number, presence: true
end
