class Student < ApplicationRecord
  belongs_to :user
  belongs_to :classroom, optional: true
  has_many :parent_student_relationships, dependent: :destroy
  has_many :parents, through: :parent_student_relationships, source: :parent

  has_one_attached :photo

  enum :status, {
    active: 0,
    inactive: 1,
    graduated: 2,
    transferred: 3
  }

  validates :admission_number, presence: true, uniqueness: true
  validates :date_of_birth, presence: true
  validates :status, presence: true
  validates :user_id, uniqueness: true

  scope :active, -> { where(status: :active) }
  scope :in_grade, ->(grade) { joins(:classroom).where(classrooms: { grade_level: grade }) }

  def full_name
    [user.first_name, user.last_name].compact.join(" ").presence || user.email_address
  end
end
