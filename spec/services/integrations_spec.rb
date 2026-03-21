# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations do
  around do |example|
    prev_sms = ENV.delete("FORCE_DISABLE_SMS")
    prev_mpesa = ENV.delete("FORCE_DISABLE_MPESA")
    prev_enable_sms = ENV.delete("ENABLE_SMS")
    prev_enable_mpesa = ENV.delete("ENABLE_MPESA")
    example.run
  ensure
    prev_sms ? ENV["FORCE_DISABLE_SMS"] = prev_sms : ENV.delete("FORCE_DISABLE_SMS")
    prev_mpesa ? ENV["FORCE_DISABLE_MPESA"] = prev_mpesa : ENV.delete("FORCE_DISABLE_MPESA")
    prev_enable_sms ? ENV["ENABLE_SMS"] = prev_enable_sms : ENV.delete("ENABLE_SMS")
    prev_enable_mpesa ? ENV["ENABLE_MPESA"] = prev_enable_mpesa : ENV.delete("ENABLE_MPESA")
  end

  describe ".sms_enabled?" do
    it "is true in test by default (local environment)" do
      expect(described_class.sms_enabled?).to be true
    end

    it "returns false when FORCE_DISABLE_SMS is set" do
      ENV["FORCE_DISABLE_SMS"] = "1"
      expect(described_class.sms_enabled?).to be false
    end
  end

  describe ".mpesa_enabled?" do
    it "is true in test by default (local environment)" do
      expect(described_class.mpesa_enabled?).to be true
    end

    it "returns false when FORCE_DISABLE_MPESA is set" do
      ENV["FORCE_DISABLE_MPESA"] = "1"
      expect(described_class.mpesa_enabled?).to be false
    end
  end
end
