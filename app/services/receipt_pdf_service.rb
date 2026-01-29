# Builds a Prawn PDF receipt for a transaction.
class ReceiptPdfService
  class << self
    # @param transaction [Transaction]
    # @return [Prawn::Document]
    def build(transaction)
      require "prawn"

      Prawn::Document.new(page_size: "A4", margin: 40) do |doc|
        doc.text "RECEIPT", size: 20, style: :bold
        doc.move_down 4
        doc.text "Learnexis", size: 10, color: "666666"
        doc.move_down 16

        doc.text "Receipt ##{transaction.id}", size: 12
        doc.move_down 8
        doc.text "Date: #{transaction.transaction_date.strftime('%d %b %Y')}", size: 11
        doc.text "Student: #{transaction.student.full_name}", size: 11
        doc.text "Admission: #{transaction.student.admission_number}", size: 10, color: "666666"
        doc.move_down 8

        if transaction.invoice_id.present?
          doc.text "Invoice: ##{transaction.invoice_id}", size: 10
          doc.move_down 4
        end

        doc.text "Amount: #{number_to_currency(transaction.amount)}", size: 14, style: :bold
        doc.move_down 4
        doc.text "Payment method: #{transaction.payment_method.humanize}", size: 10
        doc.text "Type: #{transaction.transaction_type.humanize}", size: 10
        doc.move_down 8
        doc.text "Reference: #{transaction.reference.presence || '—'}", size: 10
        doc.move_down 8
        doc.text transaction.notes.to_s, size: 9 if transaction.notes.present?
        doc.move_down 12
        doc.text "Thank you for your payment.", size: 10, color: "666666"
      end
    end

    def number_to_currency(amount)
      return "0.00" if amount.blank?
      sprintf("%.2f", amount.to_f)
    end
  end
end
