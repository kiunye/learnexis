# Renders the receipt as HTML (with CSS) and converts to PDF via Grover.
class ReceiptPdfService
  class << self
    def build(transaction)
      html = ApplicationController.render(
        template: "transactions/receipt_pdf",
        layout: false,
        assigns: { transaction: transaction },
        formats: [ :html ]
      )
      Grover.new(html, **grover_options).to_pdf
    end

    private

    def grover_options
      {
        format: "A4",
        margin: { top: "40px", right: "40px", bottom: "50px", left: "40px" },
        display_header_footer: true,
        footer_template: '<div style="font-size: 8px; color: #666; width: 100%; text-align: right; padding-right: 40px;"><span class="pageNumber"></span>/<span class="totalPages"></span></div>',
        header_template: "<div></div>"
      }
    end
  end
end
