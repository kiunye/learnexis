# frozen_string_literal: true

require "rails_helper"

RSpec.describe SmsService do
  around do |example|
    prev = ENV.delete("FORCE_DISABLE_SMS")
    example.run
  ensure
    prev ? ENV["FORCE_DISABLE_SMS"] = prev : ENV.delete("FORCE_DISABLE_SMS")
  end

  describe ".send_single" do
    it "returns false when SMS is force-disabled" do
      ENV["FORCE_DISABLE_SMS"] = "true"
      expect(described_class.send_single("254700000000", "hello")).to be false
    end

    it "returns true for valid number when enabled (local stub)" do
      expect(described_class.send_single("254700000000", "hello")).to be true
    end
  end
end
