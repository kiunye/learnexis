class ParentStudentRelationship < ApplicationRecord
  belongs_to :parent, class_name: "User"
  belongs_to :student

  validates :parent_id, uniqueness: { scope: :student_id }
  validates :relationship_type, presence: true
end
