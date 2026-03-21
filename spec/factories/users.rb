# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { "password123456" }
    password_confirmation { "password123456" }
    first_name { "Test" }
    last_name { "User" }
    role { :admin }

    trait :as_teacher do
      role { :teacher }
    end

    trait :as_parent do
      role { :parent }
      phone_number { "254712345678" }
    end

    trait :as_student do
      role { :student }
    end
  end
end
