# frozen_string_literal: true

FactoryBot.define do
  factory :student do
    user { association :user, :as_student }
    admission_number { SecureRandom.alphanumeric(8).upcase }
    date_of_birth { 10.years.ago.to_date }
    status { :active }
  end
end
