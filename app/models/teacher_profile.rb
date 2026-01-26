class TeacherProfile < ApplicationRecord
  belongs_to :user

  validates :user_id, uniqueness: true
  validates :employee_number, uniqueness: true, allow_nil: true
end
