# frozen_string_literal: true

module RequestHelpers
  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password123456" }
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
