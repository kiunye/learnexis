class Bus < ApplicationRecord
  # Kenya-style number plate: 3 letters, 3 digits, 1 letter (e.g. KCA 123A, KBA 456B)
  KENYA_PLATE_REGEX = /\A[A-Z]{2,3}\s?\d{2,3}[A-Z]\z/i

  # Associations
  has_many :transport_routes
  has_many :students, through: :transport_routes

  # Validations
  validates :bus_number, :registration_number, presence: true, uniqueness: true
  validates :bus_number, format: { with: KENYA_PLATE_REGEX, message: "must be Kenya-style (e.g. KCA 123A)" }, allow_blank: false
  validates :capacity, presence: true, numericality: { greater_than: 0 }
  validates :driver_name, :driver_phone, :driver_license_number, presence: true

  before_validation :normalize_bus_number, if: -> { bus_number.present? }

  private

  def normalize_bus_number
    self.bus_number = bus_number.to_s.strip.upcase
  end
end
