class Transaction < ApplicationRecord
  belongs_to :invoice, optional: true
  belongs_to :student
  belongs_to :recorded_by, class_name: "User", optional: true

  enum :payment_method, {
    cash: 0,
    mpesa: 1,
    bank_transfer: 2,
    cheque: 3,
    other: 4
  }

  enum :transaction_type, {
    payment: 0,
    refund: 1,
    adjustment: 2
  }

  validates :student_id, presence: true
  validates :amount, presence: true, numericality: { other_than: 0 }
  validates :transaction_date, presence: true
  validates :payment_method, presence: true
  validates :transaction_type, presence: true

  after_commit :reconcile_invoice, on: :create
  after_commit :audit_created, on: :create

  scope :for_student, ->(student) { where(student: student) }
  scope :for_invoice, ->(invoice) { where(invoice: invoice) }
  scope :payments, -> { where(transaction_type: :payment) }
  scope :refunds, -> { where(transaction_type: :refund) }
  scope :adjustments, -> { where(transaction_type: :adjustment) }

  private

  def reconcile_invoice
    return unless invoice_id.present? && payment?
    return if amount.to_d <= 0

    total_paid = Transaction.payments.for_invoice(invoice).sum(:amount)
    invoice.reload
    if total_paid >= invoice.total_amount.to_d
      invoice.update!(status: :paid)
      AuditLog.log(recorded_by, "invoice.reconciled", invoice, { total_paid: total_paid.to_f })
    end
  end

  def audit_created
    AuditLog.log(recorded_by, "transaction.created", self, { amount: amount.to_f, invoice_id: invoice_id })
  end
end
