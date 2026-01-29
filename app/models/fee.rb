class Fee < ApplicationRecord
  has_many :fee_assignments, dependent: :destroy
  has_many :students, through: :fee_assignments

  enum :fee_type, {
    tuition: 0,
    transport: 1,
    other: 2
  }

  enum :status, {
    active: 0,
    inactive: 1
  }

  validates :name, presence: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :academic_year, presence: true, numericality: { only_integer: true }
  validates :fee_type, presence: true
  validates :status, presence: true

  scope :for_academic_year, ->(year) { where(academic_year: year) }
  scope :by_type, ->(type) { where(fee_type: type) }
  scope :active_fees, -> { where(status: :active) }
end
