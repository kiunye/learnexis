# Handles M-Pesa payment integration. Development: logs only.
# Production: placeholder for Lipisha, Daraja, or similar M-Pesa provider.
class MpesaPaymentService
  class << self
    # @param phone [String] Customer phone number in format 254XXXXXXXXX
    # @param amount [Decimal] Amount to charge
    # @param reference [String] Unique reference for the transaction
    # @param description [String] Description of the transaction
    # @return [Hash] Response with success status and data or error
    def initiate_stk_push(phone, amount, reference, description = "School Fee Payment")
      return { success: false, error: "Invalid parameters" } if phone.blank? || amount.blank? || reference.blank?

      normalized_phone = phone.to_s.gsub(/^0/, "254").gsub(/^\+254/, "254")
      return { success: false, error: "Invalid phone number format" } unless normalized_phone.match?(/\A254[0-9]{9}\z/)

      amount_decimal = amount.to_d
      return { success: false, error: "Amount must be greater than zero" } if amount_decimal <= 0

      if Rails.env.development?
        Rails.logger.info "[MpesaPaymentService] Would initiate STK push to #{normalized_phone} for K#{amount_decimal} with reference #{reference}"
        # Simulate successful response in development
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
        # Example using Lipisha (adjust based on actual provider):
        # lipisha = Lipisha.new(
        #   api_key: ENV['LIPISHA_API_KEY'],
        #   api_signature: ENV['LIPISHA_API_SIGNATURE']
        # )
        # response = lipisha.mobile_money_checkout(
        #   amount: amount_decimal,
        #   phone_number: normalized_phone,
        #   transaction_description: description,
        #   reference: reference,
        #   callback_url: "#{ENV['HOST']}/mpesa/callback"
        # )
        #
        # if response.success?
        #   { success: true, data: response.data }
        # else
        #   { success: false, error: response.error_message }
        # end

        Rails.logger.info "[MpesaPaymentService] Production stub: would initiate STK push to #{normalized_phone}"
        { success: false, error: "M-Pesa integration not configured in production" }
      end
    end

    # @param callback_data [Hash] Data received from M-Pesa provider callback
    # @return [Hash] Processed transaction data or error
    def process_callback(callback_data)
      return { success: false, error: "No callback data provided" } if callback_data.blank?

      if Rails.env.development?
        Rails.logger.info "[MpesaPaymentService] Processing M-Pesa callback: #{callback_data.inspect}"

        # Simulate processing callback data in development
        {
          success: true,
          data: {
            transaction_id: "txn_#{Time.now.to_i}",
            mpesa_receipt_number: callback_data[:mpesa_receipt_number] || "MPL#{Time.now.to_i}",
            amount: callback_data[:amount] || 100.00,
            phone_number: callback_data[:phone_number] || "254700000000",
            transaction_date: Time.current,
            status: :success
          }
        }
      else
        # Production: process actual callback from M-Pesa provider
        # This would validate the callback, extract relevant data, and return processed transaction data

        # Example validation (adjust based on actual provider):
        # if valid_callback_signature?(callback_data)
        #   {
        #     success: true,
        #     data: {
        #       transaction_id: callback_data[:transaction_id],
        #       mpesa_receipt_number: callback_data[:mpesa_receipt_number],
        #       amount: callback_data[:amount].to_d,
        #       phone_number: callback_data[:phone_number],
        #       transaction_date: Time.parse(callback_data[:transaction_date]),
        #       status: callback_data[:status] == "success" ? :success : :failed
        #     }
        #   }
        # else
        #   { success: false, error: "Invalid callback signature" }
        # end

        Rails.logger.info "[MpesaPaymentService] Processing M-Pesa callback in production"
        { success: false, error: "M-Pesa callback processing not configured in production" }
      end
    end

    # @param reference [String] Transaction reference to query
    # @return [Hash] Transaction status or error
    def query_transaction_status(reference)
      return { success: false, error: "Reference is required" } if reference.blank?

      if Rails.env.development?
        Rails.logger.info "[MpesaPaymentService] Would query transaction status for reference #{reference}"
        # Simulate successful query in development
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
        # Production: query actual transaction status from M-Pesa provider
        Rails.logger.info "[MpesaPaymentService] Production stub: would query transaction status for #{reference}"
        { success: false, error: "M-Pesa transaction query not configured in production" }
      end
    end

    # @param mpesa_data [Hash] Data from successful M-Pesa transaction
    # @return [Transaction] Created transaction record or nil
    def record_transaction(mpesa_data, recorded_by = nil)
      return nil if mpesa_data.blank? || mpesa_data[:amount].blank? || mpesa_data[:phone_number].blank?

      if Rails.env.development?
        Rails.logger.info "[MpesaPaymentService] Would record M-Pesa transaction: #{mpesa_data.inspect}"

        # Find student by phone number (assuming phone number matches parent/student phone)
        student = Student.joins(:parents).find_by(parents: { phone_number: mpesa_data[:phone_number] }) ||
                Student.joins(:user).find_by(users: { phone_number: mpesa_data[:phone_number] })

        if student.present?
          # Create transaction record
          transaction = Transaction.new(
            student: student,
            amount: mpesa_data[:amount],
            transaction_type: :payment,
            payment_method: :mpesa,
            transaction_date: mpesa_data[:transaction_date] || Time.current,
            mpesa_receipt: mpesa_data[:mpesa_receipt_number],
            reference_number: mpesa_data[:reference] || "MPESA#{Time.now.to_i}",
            description: "M-Pesa Payment",
            recorded_by: recorded_by
          )

          if transaction.save
            # Try to reconcile with any pending invoices
            transaction.reconcile_invoice if transaction.invoice_id.present?
            transaction
          else
            Rails.logger.error "[MpesaPaymentService] Failed to create transaction: #{transaction.errors.full_messages}"
            nil
          end
        else
          Rails.logger.warn "[MpesaPaymentService] No student found for phone number #{mpesa_data[:phone_number]}"
          nil
        end
      else
        # Production: record actual transaction
        Rails.logger.info "[MpesaPaymentService] Production stub: would record M-Pesa transaction"
        nil
      end
    end

    private

    # Example validation method for callback signature (would be implemented based on provider docs)
    # def valid_callback_signature?(callback_data)
    #   # Implement based on provider's signature validation requirements
    #   true
    # end
  end
end
