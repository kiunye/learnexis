class ParentProfile < ApplicationRecord
  belongs_to :user
  has_many :parent_student_relationships, dependent: :destroy
  has_many :students, through: :parent_student_relationships

  validates :user_id, uniqueness: true
end
