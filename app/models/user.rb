class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  enum :role, {
    admin: 0,
    teacher: 1,
    parent: 2,
    student: 3
  }

  validates :role, presence: true
end
