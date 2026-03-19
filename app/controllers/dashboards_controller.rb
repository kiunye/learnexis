class DashboardsController < ApplicationController
  include DashboardUpdates

  def show
    cache_key = "dashboard/#{Current.user.id}/#{Current.user.role}/#{Time.current.to_i / 300}"

    @dashboard_data = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      build_dashboard_data
    end
  end

  private

  def build_dashboard_data
    today = Date.current
    month_range = today.beginning_of_month..today.end_of_month

    students_scope =
      case Current.user.role.to_sym
      when :parent
        # Parent dashboard metrics are scoped to their children
        policy_scope(Student).joins(:parents).where(parents: { id: Current.user.id })
      when :student
        policy_scope(Student).where(user_id: Current.user.id)
      else
        policy_scope(Student)
      end

    total_students = students_scope.count
    total_classrooms = policy_scope(Classroom).count

    invoices_scope =
      case Current.user.role.to_sym
      when :parent
        policy_scope(Invoice).joins(student: :parents).where(parents: { id: Current.user.id })
      when :student
        policy_scope(Invoice).joins(:student).where(students: { user_id: Current.user.id })
      else
        policy_scope(Invoice)
      end

    pending_fees_amount = invoices_scope.where(status: %i[pending overdue]).sum(:total_amount)
    pending_invoices_count = invoices_scope.where(status: %i[pending overdue]).count

    attendance_scope = Attendance.where(attendance_date: today)
    attendance_scope =
      if Current.user.parent? || Current.user.student?
        attendance_scope.where(student_id: students_scope.select(:id))
      else
        attendance_scope
      end

    attendance_total = attendance_scope.count
    attendance_present = attendance_scope.where(status: Attendance.statuses[:present]).count
    attendance_rate =
      if attendance_total.zero?
        nil
      else
        ((attendance_present.to_f / attendance_total) * 100).round(1)
      end

    transactions_scope =
      case Current.user.role.to_sym
      when :parent
        policy_scope(Transaction).joins(student: :parents).where(parents: { id: Current.user.id })
      when :student
        policy_scope(Transaction).joins(:student).where(students: { user_id: Current.user.id })
      else
        policy_scope(Transaction)
      end

    monthly_revenue = transactions_scope.payments.where(transaction_date: month_range).sum(:amount)

    {
      total_students: total_students,
      total_classrooms: total_classrooms,
      pending_fees_amount: pending_fees_amount,
      pending_invoices_count: pending_invoices_count,
      attendance_rate: attendance_rate,
      attendance_present: attendance_present,
      attendance_total: attendance_total,
      monthly_revenue: monthly_revenue
    }
  end
end
