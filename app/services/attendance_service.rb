class AttendanceService
  attr_reader :errors

  def initialize
    @errors = []
  end

  # Bulk mark attendance for a classroom on a given date
  # @param classroom [Classroom]
  # @param date [Date]
  # @param records [Array<Hash>] e.g. [{ student_id: 1, status: "present" }, ...]
  # @param marked_by [User]
  # @return [Array<Attendance>]
  def mark_attendance(classroom:, date:, records:, marked_by: nil)
    @errors = []
    return [] if date > Date.current

    attendances = []
    ActiveRecord::Base.transaction do
      records.each do |attrs|
        student_id = attrs[:student_id].to_i
        status = attrs[:status].to_s
        next if student_id.zero? || !Attendance.statuses.key?(status)

        student = classroom.students.find_by(id: student_id)
        next unless student

        attendance = Attendance.find_or_initialize_by(student: student, attendance_date: date)
        attendance.classroom = classroom
        attendance.status = status
        attendance.remarks = attrs[:remarks].presence
        attendance.marked_by = marked_by
        attendance.marked_at = Time.current

        if attendance.save
          attendances << attendance
        else
          @errors.concat(attendance.errors.full_messages)
        end
      end
    end
    attendances
  end

  # Calculate attendance percentage for a student in a date range
  # @param student [Student]
  # @param date_range [Range<Date>]
  # @return [Float] 0.0..100.0, or nil if no records
  def calculate_percentage(student, date_range)
    records = Attendance.where(student: student, attendance_date: date_range)
    return nil if records.empty?

    present_count = records.where(status: [ :present, :late ]).count
    (present_count.to_f / records.count * 100).round(1)
  end

  # Generate attendance report for a classroom in a date range
  # @param classroom [Classroom]
  # @param start_date [Date]
  # @param end_date [Date]
  # @return [Hash] summary and per-student stats
  def generate_report(classroom, start_date, end_date)
    date_range = start_date..end_date
    attendances = Attendance.for_classroom(classroom).where(attendance_date: date_range)
    students = classroom.students.includes(:user)

    by_date = attendances.group_by(&:attendance_date)
    by_student = attendances.group_by(&:student_id)

    student_stats = students.map do |student|
      student_attendances = by_student[student.id] || []
      present_count = student_attendances.count { |a| a.present? || a.late? }
      absent_count = student_attendances.count(&:absent?)
      late_count = student_attendances.count(&:late?)
      excused_count = student_attendances.count(&:excused?)
      total_days = student_attendances.size
      pct = total_days.positive? ? (present_count.to_f / total_days * 100).round(1) : nil

      {
        student: student,
        present_count: present_count,
        absent_count: absent_count,
        late_count: late_count,
        excused_count: excused_count,
        total_days: total_days,
        percentage: pct
      }
    end

    daily_totals = date_range.map do |d|
      day_records = by_date[d] || []
      {
        date: d,
        present: day_records.count { |a| a.present? || a.late? },
        absent: day_records.count(&:absent?),
        late: day_records.count(&:late?),
        excused: day_records.count(&:excused?),
        total: day_records.size
      }
    end

    {
      classroom: classroom,
      start_date: start_date,
      end_date: end_date,
      student_stats: student_stats,
      daily_totals: daily_totals,
      attendances: attendances
    }
  end

  def success?
    @errors.empty?
  end
end
