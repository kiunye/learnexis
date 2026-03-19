class Event < ApplicationRecord
  # Enums
  enum :event_type, [ :academic, :sports, :cultural, :administrative ]
  # We'll handle target_audience similarly to Notice model, but let's keep it simple for now
  # According to PRD, target_audience is an integer, we can define it as an enum if needed
  # But let's follow the same pattern as Notice for consistency
  # However, the PRD doesn't specify the exact values for target_audience in Event, so we'll leave it as an integer for now
  # and add validation if needed.

  # Associations
  belongs_to :organizer, class_name: "User", optional: true
  has_many :event_registrations, dependent: :destroy
  has_many :participants, through: :event_registrations, source: :user

  # Validations
  validates :title, :description, :location, :start_datetime, :end_datetime, presence: true
  validates :registration_required, inclusion: { in: [ true, false ] }
  validates :max_participants, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :organizer_must_be_teacher
  validate :end_datetime_after_start_datetime

  # Scopes (if needed)
  # For example, upcoming events
  scope :upcoming, -> { where("start_datetime > ?", Time.current).order(start_datetime: :asc) }

  private

  def organizer_must_be_teacher
    return if organizer_id.blank?
    return if organizer&.teacher?

    errors.add(:organizer_id, "must be a teacher")
  end

  def end_datetime_after_start_datetime
    if start_datetime.present? && end_datetime.present? && end_datetime <= start_datetime
      errors.add(:end_datetime, "must be after the start time")
    end
  end
end
