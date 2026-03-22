# Renders the invoice as HTML (with CSS) and converts to PDF via Grover (headless Chrome).
# This allows full HTML/CSS styling instead of Prawn's drawing API.
class InvoicePdfService
  class << self
    def build(invoice)
      require "grover"

      html = render_invoice_html(invoice)
      grover_options = {
        format: "A4",
        margin: {
          top: "40px",
          right: "40px",
          bottom: "50px",
          left: "40px"
        },
        display_header_footer: true,
        footer_template: '<div style="font-size: 8px; color: #666; width: 100%; text-align: right; padding-right: 40px;"><span class="pageNumber"></span>/<span class="totalPages"></span></div>',
        header_template: "<div></div>"
      }
      Grover.new(html, **grover_options).to_pdf
    end

    private

    def render_invoice_html(invoice)
      ApplicationController.render(
        template: "invoices/pdf",
        layout: false,
        assigns: { invoice: invoice },
        formats: [ :html ]
      )
    end
  end
end
