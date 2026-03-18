class ReportsController < ApplicationController
  before_action :authorize_report

  # GET /reports/financial
  def financial
    # Date range for filtering
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 1.month.ago.beginning_of_month
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.today.end_of_month

    # Financial data
    @total_income = Transaction.where(transaction_type: :income, transaction_date: @start_date..@end_date).sum(:amount)
    @total_expenses = Transaction.where(transaction_type: :expense, transaction_date: @start_date..@end_date).sum(:amount)
    @net_income = @total_income - @total_expenses

    # Income by payment method
    @income_by_method = Transaction.where(transaction_type: :income, transaction_date: @start_date..@end_date)
                                   .group(:payment_method)
                                   .sum(:amount)
                                   .transform_keys { |k| Transaction.payment_methods.key(k) || k.to_s }

    # Expenses by category (if we had expense categories, for now just show all expenses)
    @expenses_by_method = Transaction.where(transaction_type: :expense, transaction_date: @start_date..@end_date)
                                     .group(:payment_method)
                                     .sum(:amount)
                                     .transform_keys { |k| Transaction.payment_methods.key(k) || k.to_s }

    # Monthly trend (last 6 months)
    @monthly_trend = []
    6.times do |i|
      date = (@end_date - i.months).beginning_of_month
      income = Transaction.where(transaction_type: :income,
                                transaction_date: date..date.end_of_month).sum(:amount)
      expense = Transaction.where(transaction_type: :expense,
                                 transaction_date: date..date.end_of_month).sum(:amount)
      @monthly_trend << {
        month: date.strftime("%b %Y"),
        income: income,
        expense: expense,
        net: income - expense
      }
    end
    @monthly_trend.reverse! # Oldest to newest

    respond_to do |format|
      format.html
      format.csv { send_data financial_to_csv, filename: "financial_report_#{Date.today}.csv" }
      format.pdf { send_data financial_to_pdf, filename: "financial_report_#{Date.today}.pdf", type: "application/pdf" }
    end
  end

  # GET /reports/attendance
  def attendance
    # For now, we'll redirect to classroom attendance reports since we don't have a general attendance report
    # In a real implementation, this would show overall attendance statistics
    redirect_to classrooms_path, alert: "Attendance reports are available per classroom. Please select a classroom to view its attendance report."
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
    # Only admins and teachers can access reports
    authorize [ :report, params[:action].to_sym ] if action_name.in?([ "financial", "attendance", "transport", "export" ])
  end

  # CSV generation methods
  def financial_to_csv
    CSV.generate(headers: true) do |csv|
      csv << [ "Financial Report", "Generated on #{Date.today}" ]
      csv << []
      csv << [ "Summary" ]
      csv << [ "Total Income", number_to_currency(@total_income) ]
      csv << [ "Total Expenses", number_to_currency(@total_expenses) ]
      csv << [ "Net Income", number_to_currency(@net_income) ]
      csv << []
      csv << [ "Income by Payment Method" ]
      csv << [ "Method", "Amount" ]
      @income_by_method.each do |method, amount|
        csv << [ method, number_to_currency(amount) ]
      end
      csv << []
      csv << [ "Monthly Trend (Last 6 Months)" ]
      csv << [ "Month", "Income", "Expense", "Net" ]
      @monthly_trend.each do |month|
        csv << [ month[:month], number_to_currency(month[:income]), number_to_currency(month[:expense]), number_to_currency(month[:net]) ]
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
      csv << [ "Route Name", "Route Code", "Area", "Bus Number", "Student Count", "Capacity", "Occupancy Rate", "Monthly Revenue", "Available Seats" ]
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

  # PDF generation methods (simplified - in production you'd use Prawn or similar)
  def financial_to_pdf
    # This is a placeholder - in a real app you'd use Prawn to generate a proper PDF
    "PDF generation would be implemented here using Prawn or similar gem"
  end

  def transport_to_pdf
    # This is a placeholder - in a real app you'd use Prawn to generate a proper PDF
    "PDF generation would be implemented here using Prawn or similar gem"
  end
end
