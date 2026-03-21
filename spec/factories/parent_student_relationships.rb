# frozen_string_literal: true

FactoryBot.define do
  factory :parent_student_relationship do
    parent { association :user, :as_parent }
    student
    relationship_type { "parent" }
  end
end
