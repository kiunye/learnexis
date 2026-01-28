# Sends absence notifications to parents when a student is marked absent.
# Uses SmsService (development: logs only; production: plug in provider).
class AttendanceNotificationJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 5
  discard_on ActiveJob::DeserializationError

  # @param attendance_id [Integer]
  def perform(attendance_id)
    attendance = Attendance.find_by(id: attendance_id)
    unless attendance
      Rails.logger.warn "[AttendanceNotificationJob] Attendance ##{attendance_id} not found, skipping"
      return
    end

    unless attendance.absent?
      Rails.logger.debug "[AttendanceNotificationJob] Attendance ##{attendance_id} not absent, skipping"
      return
    end

    student = attendance.student
    count = SmsService.send_absence_alert(student, attendance.attendance_date)
    Rails.logger.info "[AttendanceNotificationJob] Sent #{count} absence alert(s) for attendance ##{attendance_id}"
  end
end
