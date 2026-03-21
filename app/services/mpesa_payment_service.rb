# frozen_string_literal: true

# Handles M-Pesa payment integration. Development: logs only.
# Production: plug in Lipisha, Daraja, or similar; gates via Integrations + Flipper.
class MpesaPaymentService
  class << self
    # Build a stable idempotency token from raw callback params (string or symbol keys).
    def callback_idempotency_key(raw)
      return nil if raw.blank?

      h = raw.respond_to?(:to_unsafe_h) ? raw.to_unsafe_h : raw
      h = h.stringify_keys
      receipt = h["MpesaReceiptNumber"].presence || h["mpesa_receipt_number"].presence
      checkout = h["CheckoutRequestID"].presence || h["checkout_request_id"].presence
      trans_id = h["TransactionID"].presence || h["transaction_id"].presence
      [ receipt, checkout, trans_id ].compact.join(":").presence
    end

    # @param phone [String] Customer phone number in format 254XXXXXXXXX
    # @param amount [Decimal] Amount to charge
    # @param reference [String] Unique reference for the transaction
    # @param description [String] Description of the transaction
    # @return [Hash] Response with success status and data or error
    def initiate_stk_push(phone, amount, reference, description = "School Fee Payment")
      unless Integrations.mpesa_enabled?
        return { success: false, error: "M-Pesa integration is disabled" }
      end

      return { success: false, error: "Invalid parameters" } if phone.blank? || amount.blank? || reference.blank?

      normalized_phone = phone.to_s.gsub(/^0/, "254").gsub(/^\+254/, "254")
      return { success: false, error: "Invalid phone number format" } unless normalized_phone.match?(/\A254[0-9]{9}\z/)

      amount_decimal = amount.to_d
      return { success: false, error: "Amount must be greater than zero" } if amount_decimal <= 0

      if Rails.env.local?
        Rails.logger.info "[MpesaPaymentService] Would initiate STK push to #{normalized_phone} for K#{amount_decimal} with reference #{reference}"
        {
          success: true,
          data: {
            merchant_request_id: "mg_#{Time.now.to_i}",
            checkout_request_id: "ck_#{Time.now.to_i}",
            response_code: "0",
            response_description: "Success. Request accepted for processing",
            customer_message: "Success. Request accepted for processing"
          }
        }
      else
        # Production: plug in actual M-Pesa provider (Daraja/Lipisha/etc) here.
        Rails.logger.info "[MpesaPaymentService] Production stub: would initiate STK push to #{normalized_phone}"
        { success: false, error: "M-Pesa STK not configured in production (wire Daraja/Lipisha here)" }
      end
    end

    # @param callback_data [Hash] Data received from M-Pesa provider callback
    # @return [Hash] Processed transaction data or error
    def process_callback(callback_data)
      return { success: false, error: "No callback data provided" } if callback_data.blank?
      unless Integrations.mpesa_enabled?
        return { success: false, error: "M-Pesa integration is disabled" }
      end

      if Rails.env.local?
        Rails.logger.info "[MpesaPaymentService] Processing M-Pesa callback: #{callback_data.inspect}"
        {
          success: true,
          data: {
            transaction_id: "txn_#{Time.now.to_i}",
            mpesa_receipt_number: callback_data[:mpesa_receipt_number] || callback_data["MpesaReceiptNumber"] || "MPL#{Time.now.to_i}",
            amount: (callback_data[:amount] || callback_data["Amount"] || 100.00).to_d,
            phone_number: (callback_data[:phone_number] || callback_data["PhoneNumber"] || "254700000000").to_s,
            transaction_date: Time.current,
            reference: callback_data[:reference] || callback_data["reference"],
            status: :success
          }
        }
      else
        Rails.logger.info "[MpesaPaymentService] Processing M-Pesa callback in production"
        h = callback_data.respond_to?(:to_unsafe_h) ? callback_data.to_unsafe_h : callback_data
        h = h.stringify_keys

        receipt = h["MpesaReceiptNumber"].presence || h["mpesa_receipt_number"].presence
        amount = h["Amount"] || h["TransAmount"] || h["amount"]
        phone = (h["PhoneNumber"] || h["MSISDN"] || h["phone_number"]).to_s
        phone = phone.gsub(/^0/, "254").gsub(/^\+254/, "254") if phone.present?

        if receipt.blank? && amount.blank?
          return { success: false, error: "Unrecognized M-Pesa callback payload" }
        end

        {
          success: true,
          data: {
            transaction_id: h["TransactionID"].presence || h["transaction_id"].presence || SecureRandom.hex(8),
            mpesa_receipt_number: receipt.presence || "UNKNOWN",
            amount: amount.present? ? amount.to_d : 0.to_d,
            phone_number: phone.presence || "254700000000",
            transaction_date: Time.current,
            reference: h["BillRefNumber"].presence || h["reference"].presence,
            status: :success
          }
        }
      end
    end

    # @param reference [String] Transaction reference to query
    # @return [Hash] Transaction status or error
    def query_transaction_status(reference)
      unless Integrations.mpesa_enabled?
        return { success: false, error: "M-Pesa integration is disabled" }
      end
      return { success: false, error: "Reference is required" } if reference.blank?

      if Rails.env.local?
        Rails.logger.info "[MpesaPaymentService] Would query transaction status for reference #{reference}"
        {
          success: true,
          data: {
            reference: reference,
            status: :success,
            amount: 100.00,
            mpesa_receipt_number: "MPL#{Time.now.to_i}",
            transaction_date: Time.current
          }
        }
      else
        Rails.logger.info "[MpesaPaymentService] Production stub: would query transaction status for #{reference}"
        { success: false, error: "M-Pesa transaction query not configured in production" }
      end
    end

    # @param mpesa_data [Hash] Data from successful M-Pesa transaction
    # @return [Transaction] Created transaction record or nil
    def record_transaction(mpesa_data, recorded_by = nil)
      return nil if mpesa_data.blank? || mpesa_data[:amount].blank? || mpesa_data[:phone_number].blank?
      unless Integrations.mpesa_enabled?
        Rails.logger.info "[MpesaPaymentService] Skipped record_transaction (integration disabled)"
        return nil
      end

      Rails.logger.info "[MpesaPaymentService] Recording M-Pesa transaction: #{mpesa_data.inspect}"

      student = Student.joins(:parents).find_by(parents: { phone_number: mpesa_data[:phone_number] }) ||
        Student.joins(:user).find_by(users: { phone_number: mpesa_data[:phone_number] })

      unless student.present?
        Rails.logger.warn "[MpesaPaymentService] No student found for phone number #{mpesa_data[:phone_number]}"
        return nil
      end

      transaction = Transaction.new(
        student: student,
        amount: mpesa_data[:amount].to_d,
        transaction_type: :payment,
        payment_method: :mpesa,
        transaction_date: mpesa_transaction_date(mpesa_data[:transaction_date]),
        reference: mpesa_data[:reference].presence || mpesa_data[:transaction_id].to_s.presence || "MPESA-#{SecureRandom.hex(4)}",
        notes: build_mpesa_notes(mpesa_data),
        recorded_by: recorded_by
      )

      if transaction.save
        transaction
      else
        Rails.logger.error "[MpesaPaymentService] Failed to create transaction: #{transaction.errors.full_messages}"
        nil
      end
    end

    private

    def mpesa_transaction_date(value)
      case value
      when Date
        value
      when Time, ActiveSupport::TimeWithZone
        value.to_date
      else
        Date.current
      end
    end

    def build_mpesa_notes(data)
      parts = []
      parts << "M-Pesa receipt: #{data[:mpesa_receipt_number]}" if data[:mpesa_receipt_number].present?
      parts << data[:description].to_s if data[:description].present?
      parts.join(" | ").presence
    end
  end
end
