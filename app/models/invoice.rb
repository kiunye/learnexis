class Invoice < ApplicationRecord
  belongs_to :student
  has_many :invoice_line_items, dependent: :destroy

  enum :status, {
    draft: 0,
    pending: 1,
    paid: 2,
    overdue: 3,
    cancelled: 4
  }

  validates :student_id, presence: true
  validates :issue_date, presence: true
  validates :due_date, presence: true
  validates :total_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true

  validate :due_date_after_issue_date

  scope :for_student, ->(student) { where(student: student) }
  scope :by_status, ->(status) { where(status: status) }

  def recalculate_total!
    update!(total_amount: invoice_line_items.sum(:amount))
  end

  private

  def due_date_after_issue_date
    return if due_date.blank? || issue_date.blank?
    if due_date < issue_date
      errors.add(:due_date, "must be on or after issue date")
    end
  end
end
