class Classroom < ApplicationRecord
  belongs_to :class_teacher, class_name: "User", optional: true
  has_many :students, dependent: :nullify

  validates :name, presence: true
  validates :name, uniqueness: { scope: :academic_year, message: "must be unique within academic year" }
  validates :grade_level, presence: true, inclusion: { in: 1..8 }
  validates :capacity, presence: true, numericality: { greater_than: 0 }
  validates :academic_year, presence: true

  scope :for_academic_year, ->(year) { where(academic_year: year) }
  scope :by_grade_level, ->(grade) { where(grade_level: grade) }

  def full?
    students.count >= capacity
  end

  def current_students_count
    students.count
  end
end
