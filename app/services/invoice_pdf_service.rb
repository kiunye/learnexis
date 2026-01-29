# Builds a Prawn PDF for an invoice (header, line items, totals).
class InvoicePdfService
  class << self
    # @param invoice [Invoice]
    # @return [Prawn::Document]
    def build(invoice)
      require "prawn"
      require "prawn/table"

      Prawn::Document.new(page_size: "A4", margin: 40) do |doc|
        # Header
        doc.text "Invoice ##{invoice.id}", size: 20, style: :bold
        doc.move_down 4
        doc.text "Learnexis", size: 10, color: "666666"
        doc.move_down 16

        # Student & dates
        doc.text "Bill to: #{invoice.student.full_name}", size: 11
        doc.text "Admission: #{invoice.student.admission_number}", size: 10, color: "666666"
        doc.move_down 8
        doc.text "Issue date: #{invoice.issue_date.strftime('%d %b %Y')}", size: 10
        doc.text "Due date: #{invoice.due_date.strftime('%d %b %Y')}", size: 10
        doc.move_down 16

        # Line items table
        rows = [ [ "Description", "Qty", "Unit Amount", "Amount" ] ]
        invoice.invoice_line_items.each do |line|
          rows << [
            line.description,
            line.quantity.to_s,
            number_to_currency(line.unit_amount),
            number_to_currency(line.amount)
          ]
        end

        doc.table(rows, header: true, width: doc.bounds.width) do |t|
          t.row(0).style(background_color: "E8E8E8", font_style: :bold)
        end

        doc.move_down 16
        doc.text "Total: #{number_to_currency(invoice.total_amount)}", size: 12, style: :bold
        doc.move_down 8
        doc.text "Status: #{invoice.status.humanize}", size: 10, color: "666666"
        doc.move_down 8
        doc.text invoice.notes.to_s, size: 9 if invoice.notes.present?
      end
    end

    def number_to_currency(amount)
      return "0.00" if amount.blank?
      sprintf("%.2f", amount.to_f)
    end
  end
end
