# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Transactions M-Pesa", type: :request do
  describe "POST /transactions/mpesa_callback" do
    let(:parent) { create(:user, :as_parent, phone_number: "254788001122") }
    let(:student) { create(:student) }

    before { create(:parent_student_relationship, parent: parent, student: student) }

    it "creates a transaction from callback params" do
      expect do
        post mpesa_callback_transactions_path,
             params: {
               phone_number: "254788001122",
               amount: 40,
               mpesa_receipt_number: "R-mpesa-1"
             }
      end.to change(Transaction, :count).by(1)

      expect(response).to have_http_status(:ok)
    end

    it "returns duplicate message for same idempotency key" do
      post mpesa_callback_transactions_path,
           params: {
             phone_number: "254788001122",
             amount: 40,
             mpesa_receipt_number: "R-dedupe"
           }
      expect(response).to have_http_status(:ok)

      post mpesa_callback_transactions_path,
           params: {
             phone_number: "254788001122",
             amount: 40,
             mpesa_receipt_number: "R-dedupe"
           }
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["message"]).to eq("Duplicate callback ignored")
    end

    it "returns 422 when integration is disabled" do
      ENV["FORCE_DISABLE_MPESA"] = "1"
      post mpesa_callback_transactions_path,
           params: { phone_number: "254788001122", amount: 10, mpesa_receipt_number: "X" }
      expect(response).to have_http_status(:unprocessable_entity)
    ensure
      ENV.delete("FORCE_DISABLE_MPESA")
    end

    context "when MPESA_WEBHOOK_SECRET is set" do
      around do |example|
        prev = ENV["MPESA_WEBHOOK_SECRET"]
        ENV["MPESA_WEBHOOK_SECRET"] = "testsecret"
        example.run
      ensure
        prev ? ENV["MPESA_WEBHOOK_SECRET"] = prev : ENV.delete("MPESA_WEBHOOK_SECRET")
      end

      it "rejects missing or bad signature" do
        post mpesa_callback_transactions_path,
             params: { phone_number: "254788001122", amount: 10, mpesa_receipt_number: "SIG1" }
        expect(response).to have_http_status(:unauthorized)
      end

      it "accepts a valid HMAC signature" do
        payload = { phone_number: "254788001122", amount: 40, mpesa_receipt_number: "R-signed" }
        body = ActiveSupport::JSON.encode(payload)
        sig = OpenSSL::HMAC.hexdigest("SHA256", "testsecret", body)

        expect do
          post mpesa_callback_transactions_path,
               params: payload,
               as: :json,
               headers: { "X-Learnexis-Mpesa-Signature" => sig }
        end.to change(Transaction, :count).by(1)

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /transactions/verify_mpesa" do
    let(:admin) { create(:user) }

    before { sign_in_as(admin) }

    it "returns data when reference is present" do
      get verify_mpesa_transactions_path, params: { reference: "REF-XYZ" }
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["success"]).to be true
    end

    it "returns 400 when reference is missing" do
      get verify_mpesa_transactions_path
      expect(response).to have_http_status(:bad_request)
    end
  end
end
