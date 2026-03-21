# Renders the transport report as HTML (with CSS) and converts to PDF via Grover.
class TransportReportPdfService
  class << self
    def build(transport_data:, total_students_assigned:, total_capacity:, overall_occupancy:)
      html = ApplicationController.render(
        template: "reports/transport_pdf",
        layout: false,
        assigns: {
          transport_data: transport_data,
          total_students_assigned: total_students_assigned,
          total_capacity: total_capacity,
          overall_occupancy: overall_occupancy
        },
        formats: [:html]
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
