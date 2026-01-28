class Attendance < ApplicationRecord
  belongs_to :student
  belongs_to :classroom
  belongs_to :marked_by, class_name: "User", optional: true

  enum :status, {
    present: 0,
    absent: 1,
    late: 2,
    excused: 3
  }

  validates :student_id, uniqueness: { scope: :attendance_date, message: "already has attendance for this date" }
  validates :attendance_date, presence: true
  validates :status, presence: true
  validate :attendance_date_not_future

  before_save :set_marked_at, if: :marked_by_id_changed?
  after_commit :enqueue_absence_notification, on: [ :create, :update ]

  scope :for_date, ->(date) { where(attendance_date: date) }
  scope :for_classroom, ->(classroom) { where(classroom: classroom) }

  private

  def attendance_date_not_future
    return unless attendance_date.present?
    if attendance_date > Date.current
      errors.add(:attendance_date, "cannot be in the future")
    end
  end

  def set_marked_at
    self.marked_at = Time.current
  end

  def enqueue_absence_notification
    return unless absent?
    return unless saved_change_to_status?

    AttendanceNotificationJob.perform_later(id)
  end
end
