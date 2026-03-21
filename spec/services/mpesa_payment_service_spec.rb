# frozen_string_literal: true

require "rails_helper"

RSpec.describe MpesaPaymentService do
  around do |example|
    prev = ENV.delete("FORCE_DISABLE_MPESA")
    example.run
  ensure
    prev ? ENV["FORCE_DISABLE_MPESA"] = prev : ENV.delete("FORCE_DISABLE_MPESA")
  end

  describe ".callback_idempotency_key" do
    it "builds a key from receipt and checkout id" do
      key = described_class.callback_idempotency_key(
        "MpesaReceiptNumber" => "R1",
        "CheckoutRequestID" => "CK1"
      )
      expect(key).to eq("R1:CK1")
    end
  end

  describe ".initiate_stk_push" do
    it "rejects when M-Pesa is disabled" do
      ENV["FORCE_DISABLE_MPESA"] = "1"
      result = described_class.initiate_stk_push("254712345678", 10, "REF1")
      expect(result[:success]).to be false
    end

    it "succeeds in test for valid input" do
      result = described_class.initiate_stk_push("254712345678", 10, "REF1")
      expect(result[:success]).to be true
    end
  end

  describe ".record_transaction" do
    it "creates a transaction linked to parent phone" do
      parent = create(:user, :as_parent, phone_number: "254799000111")
      student = create(:student)
      create(:parent_student_relationship, parent: parent, student: student)

      tx = described_class.record_transaction(
        {
          amount: 25.5,
          phone_number: "254799000111",
          mpesa_receipt_number: "ABC123",
          transaction_date: Date.current,
          transaction_id: "T1",
          reference: "REF-1"
        }
      )

      expect(tx).to be_persisted
      expect(tx.payment_method).to eq("mpesa")
      expect(tx.reference).to eq("REF-1")
      expect(tx.notes).to include("ABC123")
    end
  end
end
