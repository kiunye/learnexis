# Generates invoices from fee assignments (per-student or bulk).
# Creates Invoice + InvoiceLineItem records; uses FeeCalculationService for amounts.
class InvoiceGenerationService
  attr_reader :errors

  def initialize
    @errors = []
  end

  # @param student [Student]
  # @param issue_date [Date]
  # @param due_date [Date]
  # @param fee_assignment_ids [Array<Integer>, nil] optional; if nil, uses all pending/partial fee assignments for student
  # @param status [String, Symbol] :draft or :pending
  # @return [Invoice, nil]
  def generate_for_student(student:, issue_date:, due_date:, fee_assignment_ids: nil, status: :draft)
    @errors = []
    return nil unless student.present? && issue_date.present? && due_date.present?

    assignments = fee_assignments_for(student, fee_assignment_ids)
    return nil if assignments.empty? && @errors.empty?

    invoice = nil
    ActiveRecord::Base.transaction do
      invoice = Invoice.create!(
        student: student,
        issue_date: issue_date,
        due_date: due_date,
        total_amount: 0,
        status: status.to_s
      )

      total = 0
      assignments.each do |fa|
        calc = FeeCalculationService.calculate(fa)
        next if calc.net_amount.to_d.zero?

        line = invoice.invoice_line_items.create!(
          fee_assignment_id: fa.id,
          description: "#{fa.fee.name} (#{fa.fee.fee_type})",
          quantity: 1,
          unit_amount: calc.net_amount,
          amount: calc.net_amount
        )
        total += line.amount
      end

      invoice.update!(total_amount: total)
    end

    invoice
  rescue ActiveRecord::RecordInvalid => e
    @errors << e.message
    nil
  end

  # @param student_ids [Array<Integer>]
  # @param issue_date [Date]
  # @param due_date [Date]
  # @param status [String, Symbol]
  # @return [Array<Invoice>]
  def bulk_generate(student_ids:, issue_date:, due_date:, status: :draft)
    @errors = []
    invoices = []
    Array(student_ids).each do |student_id|
      student = Student.find_by(id: student_id)
      unless student
        @errors << "Student ##{student_id} not found"
        next
      end

      inv = generate_for_student(
        student: student,
        issue_date: issue_date,
        due_date: due_date,
        status: status
      )
      invoices << inv if inv
    end
    invoices
  end

  def success?
    @errors.empty?
  end

  private

  def fee_assignments_for(student, fee_assignment_ids)
    scope = student.fee_assignments.where(status: [ :pending, :partial ])
    if fee_assignment_ids.present?
      scope = scope.where(id: fee_assignment_ids)
    end
    scope.includes(:fee).to_a
  end
end
