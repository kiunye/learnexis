module Classrooms
  class AttendancesController < ApplicationController
    before_action :set_classroom
    before_action :authorize_attendance

    def index
      @date = params[:date].present? ? Date.parse(params[:date]) : Date.current
      @date = Date.current if @date > Date.current

      @students = @classroom.students.includes(:user).order("users.first_name, users.last_name").references(:users)
      @attendances_by_student = Attendance.for_classroom(@classroom).for_date(@date).index_by(&:student_id)
    end

    def mark
      @date = params[:date].present? ? Date.parse(params[:date]) : Date.current
      @date = Date.current if @date > Date.current

      @students = @classroom.students.includes(:user).order("users.first_name, users.last_name").references(:users)
      @attendances_by_student = Attendance.for_classroom(@classroom).for_date(@date).index_by(&:student_id)
    end

    def update
      date = params[:date].present? ? Date.parse(params[:date]) : Date.current
      date = Date.current if date > Date.current

      raw = permitted_attendances || []
      records = Array(raw).map do |attrs|
        {
          student_id: attrs[:student_id] || attrs["student_id"],
          status: (attrs[:status] || attrs["status"]).presence || "present",
          remarks: attrs[:remarks] || attrs["remarks"]
        }
      end

      service = AttendanceService.new
      service.mark_attendance(
        classroom: @classroom,
        date: date,
        records: records,
        marked_by: Current.user
      )

      if service.success?
        redirect_to classroom_attendances_path(@classroom, date: date), notice: "Attendance saved."
      else
        redirect_to mark_classroom_attendances_path(@classroom, date: date), alert: "Could not save attendance: #{service.errors.join(', ')}"
      end
    end

    def reports
      @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.current.beginning_of_month
      @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current
      @end_date = @start_date if @end_date < @start_date

      service = AttendanceService.new
      @report = service.generate_report(@classroom, @start_date, @end_date)
    end

    private

    def set_classroom
      @classroom = Classroom.find(params[:classroom_id])
    end

    def authorize_attendance
      case action_name
      when "index", "mark"
        authorize @classroom, :show?
      when "update"
        authorize @classroom, :update?
      when "reports"
        authorize @classroom, :show?
      else
        authorize @classroom, :show?
      end
    end

    def permitted_attendances
      params.permit(attendances: %i[student_id status remarks])[:attendances]
    end
  end
end
