# Renders the financial report as HTML (with CSS) and converts to PDF via Grover.
class FinancialReportPdfService
  class << self
    def build(start_date:, end_date:, total_collections:, total_refunds:, total_adjustments:, net:,
              collections_by_method:, refunds_by_method:, monthly_trend:)
      html = ApplicationController.render(
        template: "reports/financial_pdf",
        layout: false,
        assigns: {
          start_date: start_date,
          end_date: end_date,
          total_collections: total_collections,
          total_refunds: total_refunds,
          total_adjustments: total_adjustments,
          net: net,
          collections_by_method: collections_by_method,
          refunds_by_method: refunds_by_method,
          monthly_trend: monthly_trend
        },
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
