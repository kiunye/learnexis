class FeeAssignment < ApplicationRecord
  belongs_to :fee
  belongs_to :student

  enum :status, {
    pending: 0,
    partial: 1,
    paid: 2,
    cancelled: 3
  }

  validates :fee_id, uniqueness: { scope: :student_id, message: "already assigned to this student" }
  validates :discount_percent, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :discount_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :installment_count, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  def effective_amount
    return 0 if exempt?
    base = amount_override.presence || fee.amount
    return base if base.to_d.zero?
    pct = (discount_percent.presence || 0).to_d
    amt = (discount_amount.presence || 0).to_d
    discount = amt + (base * pct / 100)
    [ base - discount, 0 ].max
  end
end
