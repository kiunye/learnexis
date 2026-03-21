# frozen_string_literal: true

# Central gates for outbound/inbound integrations. Development and test are permissive
# unless +FORCE_DISABLE_*+ is set. Production requires explicit +ENABLE_*+ and Flipper.
module Integrations
  TRUTHY = %w[1 true yes on].freeze

  class << self
    def truthy_env?(value)
      TRUTHY.include?(value.to_s.downcase)
    end

    # SMS (Africastalking, etc.)
    def sms_enabled?
      return false if truthy_env?(ENV["FORCE_DISABLE_SMS"])
      return true if Rails.env.local?

      truthy_env?(ENV.fetch("ENABLE_SMS", "false")) && Flipper.enabled?(:sms)
    end

    # M-Pesa STK, callbacks, and status checks
    def mpesa_enabled?
      return false if truthy_env?(ENV["FORCE_DISABLE_MPESA"])
      return true if Rails.env.local?

      truthy_env?(ENV.fetch("ENABLE_MPESA", "false")) && Flipper.enabled?(:mpesa)
    end
  end
end
