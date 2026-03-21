class ReportsController < ApplicationController
  before_action :authorize_report

  # GET /reports
  def index
    @start_date = 1.month.ago.to_date
    @end_date = Date.current

    if policy(:report).financial?
      range = @start_date..@end_date
      base = Transaction.where(transaction_date: range)
      collections = base.payments.sum(:amount)
      refunds = base.refunds.sum(:amount)

      @financial_summary = {
        total_collections: collections,
        total_refunds: refunds,
        net: collections - refunds
      }
    end

    if policy(:report).attendance?
      att_scope = policy_scope(Attendance).where(attendance_date: @start_date..@end_date)
      total = att_scope.count
      present = att_scope.present.count

      @attendance_summary = {
        total_records: total,
        present_percent: total.positive? ? (present.to_f / total * 100).round(1) : 0.0
      }
    end

    if policy(:report).transport?
      routes = TransportRoute.all
      total_students_assigned = routes.sum { |r| r.students.count }
      total_capacity = routes.sum { |r| r.bus&.capacity || 0 }
      overall_occupancy = total_capacity.positive? ? (total_students_assigned.to_f / total_capacity * 100).round(1) : 0.0

      @transport_summary = {
        total_students_assigned: total_students_assigned,
        overall_occupancy: overall_occupancy
      }
    end
  end

  # GET /reports/financial
  def financial
    # Date range for filtering
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 1.month.ago.beginning_of_month
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.today.end_of_month

    # Ledger-aligned: payment = money in, refund = money out, adjustment = +/- correction
    range = @start_date..@end_date
    base = Transaction.where(transaction_date: range)

    @total_collections = base.payments.sum(:amount)
    @total_refunds = base.refunds.sum(:amount)
    @total_adjustments = base.adjustments.sum(:amount)
    @net = @total_collections - @total_refunds + @total_adjustments

    # Collections by payment method
    @collections_by_method = base.payments
                                 .group(:payment_method)
                                 .sum(:amount)
                                 .transform_keys { |k| Transaction.payment_methods.key(k) || k.to_s }

    # Refunds by payment method
    @refunds_by_method = base.refunds
                             .group(:payment_method)
                             .sum(:amount)
                             .transform_keys { |k| Transaction.payment_methods.key(k) || k.to_s }

    # Monthly trend (last 6 months)
    @monthly_trend = []
    6.times do |i|
      date = (@end_date - i.months).beginning_of_month
      month_range = date..date.end_of_month
      collections = Transaction.where(transaction_date: month_range).payments.sum(:amount)
      refunds = Transaction.where(transaction_date: month_range).refunds.sum(:amount)
      adjustments = Transaction.where(transaction_date: month_range).adjustments.sum(:amount)
      @monthly_trend << {
        month: date.strftime("%b %Y"),
        collections: collections,
        refunds: refunds,
        adjustments: adjustments,
        net: collections - refunds + adjustments
      }
    end
    @monthly_trend.reverse!

    respond_to do |format|
      format.html
      format.csv { send_data financial_to_csv, filename: "financial_report_#{Date.today}.csv" }
      format.pdf { send_data financial_to_pdf, filename: "financial_report_#{Date.today}.pdf", type: "application/pdf" }
    end
  end

  # GET /reports/attendance — role-scoped: admin (all), teacher (their classrooms), parent (their children)
  def attendance
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 1.month.ago.beginning_of_month
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current

    base = policy_scope(Attendance).includes(student: :user).includes(:classroom)
    base = base.where(attendance_date: @start_date..@end_date)
    base = base.where(classroom_id: params[:classroom_id]) if params[:classroom_id].present?
    base = base.where(student_id: params[:student_id]) if params[:student_id].present?

    @attendances = base.order(attendance_date: :desc, student_id: :asc).limit(500)

    # Summary: counts by status in period
    summary_scope = policy_scope(Attendance).where(attendance_date: @start_date..@end_date)
    summary_scope = summary_scope.where(classroom_id: params[:classroom_id]) if params[:classroom_id].present?
    summary_scope = summary_scope.where(student_id: params[:student_id]) if params[:student_id].present?
    @total_records = summary_scope.count
    @present_count = summary_scope.present.count
    @absent_count = summary_scope.absent.count
    @late_count = summary_scope.late.count
    @excused_count = summary_scope.excused.count
    @present_percent = @total_records.positive? ? (@present_count.to_f / @total_records * 100).round(1) : 0

    @classrooms = policy_scope(Classroom).order(:name)
    @students = policy_scope(Student).joins(:user).includes(:user).order("users.first_name", "users.last_name")
  end

  # GET /reports/transport
  def transport
    @transport_routes = TransportRoute.all

    @transport_data = @transport_routes.map do |route|
      {
        route: route,
        student_count: route.students.count,
        capacity: route.bus&.capacity || 0,
        occupancy_rate: route.occupancy_rate,
        monthly_revenue: route.students.count * route.monthly_fee,
        available_seats: route.available_seats
      }
    end

    @total_students_assigned = @transport_routes.sum { |route| route.students.count }
    @total_capacity = @transport_routes.sum { |route| route.bus&.capacity || 0 }
    @overall_occupancy = @total_capacity > 0 ? (@total_students_assigned.to_f / @total_capacity) * 100 : 0

    respond_to do |format|
      format.html
      format.csv { send_data transport_to_csv, filename: "transport_report_#{Date.today}.csv" }
      format.pdf { send_data transport_to_pdf, filename: "transport_report_#{Date.today}.pdf", type: "application/pdf" }
    end
  end

  # GET /reports/export
  def export
    # This would handle exporting various reports
    report_type = params[:type] || "financial"
    format = params[:format] || "csv"

    case report_type
    when "financial"
      redirect_to financial_reports_path(format: format)
    when "transport"
      redirect_to transport_reports_path(format: format)
    else
      redirect_to financial_reports_path(format: format)
    end
  end

  private

  def authorize_report
    return unless action_name.in?([ "index", "financial", "attendance", "transport", "export" ])

    # Use ReportPolicy (symbol record), not a namespaced policy.
    authorize :report, "#{action_name}?"
  end

  # CSV generation methods (aligned to ledger: payment / refund / adjustment)
  def financial_to_csv
    CSV.generate(headers: true) do |csv|
      csv << [ "Financial Report", "Generated on #{Date.today}" ]
      csv << []
      csv << [ "Summary" ]
      csv << [ "Total Collections (Payments)", number_to_currency(@total_collections) ]
      csv << [ "Total Refunds", number_to_currency(@total_refunds) ]
      csv << [ "Total Adjustments", number_to_currency(@total_adjustments) ]
      csv << [ "Net", number_to_currency(@net) ]
      csv << []
      csv << [ "Collections by Payment Method" ]
      csv << [ "Method", "Amount" ]
      @collections_by_method.each do |method, amount|
        csv << [ method, number_to_currency(amount) ]
      end
      csv << []
      csv << [ "Refunds by Payment Method" ]
      csv << [ "Method", "Amount" ]
      @refunds_by_method.each do |method, amount|
        csv << [ method, number_to_currency(amount) ]
      end
      csv << []
      csv << [ "Monthly Trend (Last 6 Months)" ]
      csv << [ "Month", "Collections", "Refunds", "Adjustments", "Net" ]
      @monthly_trend.each do |month|
        csv << [
          month[:month],
          number_to_currency(month[:collections]),
          number_to_currency(month[:refunds]),
          number_to_currency(month[:adjustments]),
          number_to_currency(month[:net])
        ]
      end
    end
  end

  def transport_to_csv
    CSV.generate(headers: true) do |csv|
      csv << [ "Transport Report", "Generated on #{Date.today}" ]
      csv << []
      csv << [ "Summary" ]
      csv << [ "Total Students Assigned", @total_students_assigned ]
      csv << [ "Total Capacity", @total_capacity ]
      csv << [ "Overall Occupancy Rate", "#{number_with_precision(@overall_occupancy, precision: 1)}%" ]
      csv << []
      csv << [ "Route Details" ]
      csv << [ "Route Name", "Route Code", "Area", "Bus (Number Plate)", "Student Count", "Capacity", "Occupancy Rate", "Monthly Revenue", "Available Seats" ]
      @transport_data.each do |data|
        csv << [
          data[:route].name,
          data[:route].route_code,
          data[:route].area,
          data[:route].bus&.bus_number || "Not Assigned",
          data[:student_count],
          data[:capacity],
          "#{number_with_precision(data[:occupancy_rate], precision: 1)}%",
          number_to_currency(data[:monthly_revenue]),
          data[:available_seats]
        ]
      end
    end
  end

  # PDF generation (Prawn) – returns PDF binary; controller sends via send_data
  def financial_to_pdf
    FinancialReportPdfService.build(
      start_date: @start_date,
      end_date: @end_date,
      total_collections: @total_collections,
      total_refunds: @total_refunds,
      total_adjustments: @total_adjustments,
      net: @net,
      collections_by_method: @collections_by_method,
      refunds_by_method: @refunds_by_method,
      monthly_trend: @monthly_trend
    )
  end

  def transport_to_pdf
    TransportReportPdfService.build(
      transport_data: @transport_data,
      total_students_assigned: @total_students_assigned,
      total_capacity: @total_capacity,
      overall_occupancy: @overall_occupancy
    )
  end
end
