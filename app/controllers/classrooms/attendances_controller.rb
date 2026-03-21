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

      records = permitted_attendance_rows.map do |attrs|
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
        @date = date
        @students = @classroom.students.includes(:user).order("users.first_name, users.last_name").references(:users)
        @attendances_by_student = Attendance.for_classroom(@classroom).for_date(@date).index_by(&:student_id)
        @summary = attendance_summary_for(@attendances_by_student)

        respond_to do |format|
          format.html { redirect_to classroom_attendances_path(@classroom, date: date), notice: "Attendance saved." }
          format.turbo_stream do
            render :update, status: :ok
          end
        end
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
      @classroom = policy_scope(Classroom).find(params[:classroom_id])
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

    # Form sends attendances[0][student_id], … — strong params returns a Hash, not an Array.
    def permitted_attendance_rows
      raw = params[:attendances]
      return [] if raw.blank?

      rows =
        if raw.is_a?(ActionController::Parameters)
          raw.values
        elsif raw.is_a?(Hash)
          raw.values
        else
          Array(raw)
        end

      rows.filter_map do |row|
        next unless row.is_a?(ActionController::Parameters) || row.is_a?(Hash)

        h = row.is_a?(ActionController::Parameters) ? row.permit(:student_id, :status, :remarks) : row.slice("student_id", "status", "remarks")
        h.to_h.symbolize_keys
      end
    end

    def attendance_summary_for(attendances_by_student)
      present = absent = late = excused = 0
      attendances_by_student.each_value do |a|
        case a.status
        when "present" then present += 1
        when "absent" then absent += 1
        when "late" then late += 1
        when "excused" then excused += 1
        end
      end
      { present: present, absent: absent, late: late, excused: excused, total: attendances_by_student.size }
    end
  end
end
