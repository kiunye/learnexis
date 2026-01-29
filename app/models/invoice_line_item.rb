class InvoiceLineItem < ApplicationRecord
  belongs_to :invoice
  belongs_to :fee_assignment, optional: true

  validates :description, presence: true
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_validation :set_amount_from_quantity_and_unit, if: -> { quantity.present? && unit_amount.present? }

  private

  def set_amount_from_quantity_and_unit
    self.amount = (quantity * unit_amount).round(2)
  end
end
