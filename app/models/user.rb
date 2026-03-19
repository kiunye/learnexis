class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  has_one :teacher_profile, dependent: :destroy
  has_one :parent_profile, dependent: :destroy
  has_one :student, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  enum :role, {
    admin: 0,
    teacher: 1,
    parent: 2,
    student: 3
  }

  validates :role, presence: true

  scope :teachers, -> { where(role: :teacher).order(:first_name, :last_name) }

  def profile
    case role
    when "teacher"
      teacher_profile
    when "parent"
      parent_profile
    when "student"
      student
    else
      nil
    end
  end

  def admin?
    role == "admin"
  end

  def teacher?
    role == "teacher"
  end

  def parent?
    role == "parent"
  end

  def student?
    role == "student"
  end

  def full_name
    [ first_name, last_name ].compact.join(" ").presence || email_address
  end

  def full_name_with_email
    name = full_name
    name == email_address ? email_address : "#{name} (#{email_address})"
  end
end
