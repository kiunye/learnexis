class TransportRoute < ApplicationRecord
  # Associations
  belongs_to :bus, optional: true
  has_many :students

  # Validations
  validates :name, :route_code, presence: true, uniqueness: true
  validates :monthly_fee, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :area, inclusion: { in: %w[North South East West] }, allow_nil: true
  validates :pickup_time, :dropoff_time, presence: true
  validate :dropoff_time_after_pickup_time

  # For storing stops as JSON array
  serialize :stops, coder: JSON

  # Instance methods
  def occupancy_rate
    bus_capacity = bus&.capacity || 0
    return 0 if bus_capacity.zero?
    (students.count.to_f / bus_capacity) * 100
  end

  def full?
    occupancy_rate >= 100
  end

  def near_full?
    occupancy_rate >= 80 && occupancy_rate < 100
  end

  def available_seats
    [ 0, (bus&.capacity || 0) - students.count ].max
  end

  private

  def dropoff_time_after_pickup_time
    if pickup_time.present? && dropoff_time.present? && dropoff_time <= pickup_time
      errors.add(:dropoff_time, "must be after pickup time")
    end
  end
end
