class TransactionsController < ApplicationController
  allow_unauthenticated_access only: %i[mpesa_callback]
  skip_before_action :verify_authenticity_token, only: %i[mpesa_callback]

  before_action :verify_mpesa_webhook_signature!, only: %i[mpesa_callback]

  before_action :set_transaction, only: %i[show edit update destroy download]
  before_action :authorize_transaction, only: %i[show edit update destroy download]

  def index
    authorize Transaction

    scope = policy_scope(Transaction).includes({ student: :user }, :invoice, :recorded_by)
    @filter_students = policy_scope(Student).includes(:user).joins(:user).order("users.last_name", "users.first_name")

    if params[:student_id].present?
      scope = scope.where(student_id: params[:student_id])
    end

    if params[:invoice_id].present?
      scope = scope.where(invoice_id: params[:invoice_id])
    end

    if params[:payment_method].present? && Transaction.payment_methods.key?(params[:payment_method])
      scope = scope.where(payment_method: params[:payment_method])
    end

    @pagy, @transactions = pagy(
      scope.order(transaction_date: :desc, created_at: :desc),
      limit: 20
    )

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
  end

  def new
    authorize Transaction
    @transaction = Transaction.new
    @transaction.transaction_date = Date.current
    @transaction.transaction_type = :payment
    @transaction.payment_method = :cash
    @transaction.invoice_id = params[:invoice_id] if params[:invoice_id].present?
    if @transaction.invoice_id.present?
      inv = Invoice.find_by(id: @transaction.invoice_id)
      @transaction.student_id = inv&.student_id
    end
    @invoices = policy_scope(Invoice).includes(:student).where(status: [ :pending, :overdue ])
    @students = policy_scope(Student).includes(:user).joins(:user).order("users.last_name", "users.first_name")
  end

  def create
    authorize Transaction

    @transaction = Transaction.new(transaction_params)
    @transaction.recorded_by = Current.user

    if @transaction.save
      redirect_to transaction_path(@transaction), notice: "Payment recorded successfully.#{@transaction.invoice&.reload&.paid? ? ' Invoice marked as paid.' : ''}"
    else
      @invoices = policy_scope(Invoice).includes(:student).where(status: [ :pending, :overdue ])
      @students = policy_scope(Student).includes(:user).joins(:user).order("users.last_name", "users.first_name")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @invoices = policy_scope(Invoice).includes(:student)
    @students = policy_scope(Student).includes(:user).joins(:user).order("users.last_name", "users.first_name")
  end

  def update
    if @transaction.update(transaction_params)
      redirect_to transaction_path(@transaction), notice: "Transaction updated successfully."
    else
      @invoices = policy_scope(Invoice).includes(:student)
      @students = policy_scope(Student).includes(:user).joins(:user).order("users.last_name", "users.first_name")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @transaction.destroy
      redirect_to transactions_path, notice: "Transaction deleted successfully."
    else
      redirect_to transaction_path(@transaction), alert: "Failed to delete transaction."
    end
  end

  # M-Pesa callback (webhook — unauthenticated; optional HMAC via MPESA_WEBHOOK_SECRET)
  def mpesa_callback
    callback_data = params.except(:controller, :action, :format).to_unsafe_h

    dedupe_key = mpesa_idempotency_cache_key(callback_data)
    if dedupe_key.present? && Rails.cache.exist?(dedupe_key)
      render json: { success: true, message: "Duplicate callback ignored" }, status: :ok
      return
    end

    result = MpesaPaymentService.process_callback(callback_data)

    if result[:success] && result[:data].present?
      transaction = MpesaPaymentService.record_transaction(result[:data])

      if transaction.present?
        Rails.cache.write(dedupe_key, true, expires_in: 72.hours) if dedupe_key.present?
        render json: { success: true, message: "M-Pesa payment processed successfully" }, status: :ok
      else
        render json: { success: false, error: "Failed to record transaction" }, status: :unprocessable_entity
      end
    else
      render json: { success: false, error: result[:error] || "Invalid callback data" }, status: :unprocessable_entity
    end
  end

  # Verify M-Pesa transaction status (staff only)
  def verify_mpesa
    authorize Transaction, :verify_mpesa?

    unless Integrations.mpesa_enabled?
      render json: { success: false, error: "M-Pesa integration is disabled" }, status: :forbidden
      return
    end

    reference = params[:reference]

    if reference.blank?
      render json: { success: false, error: "Reference is required" }, status: :bad_request
      return
    end

    result = MpesaPaymentService.query_transaction_status(reference)

    if result[:success]
      render json: { success: true, data: result[:data] }, status: :ok
    else
      render json: { success: false, error: result[:error] }, status: :unprocessable_entity
    end
  end

  def download
    pdf = ReceiptPdfService.build(@transaction)
    send_data pdf,
              filename: "receipt-#{@transaction.id}.pdf",
              type: "application/pdf",
              disposition: "inline"
  end

  private

  def verify_mpesa_webhook_signature!
    secret = ENV["MPESA_WEBHOOK_SECRET"].to_s
    return if secret.blank?

    body = request.raw_post.to_s
    provided = request.headers["X-Learnexis-Mpesa-Signature"].to_s
    expected = OpenSSL::HMAC.hexdigest("SHA256", secret, body)
    return if provided.present? && ActiveSupport::SecurityUtils.secure_compare(provided, expected)

    head :unauthorized
  end

  def mpesa_idempotency_cache_key(callback_data)
    token = MpesaPaymentService.callback_idempotency_key(callback_data)
    return nil if token.blank?

    "mpesa/webhook/#{Digest::SHA256.hexdigest(token)}"
  end

  def set_transaction
    @transaction = Transaction.find(params[:id])
  end

  def authorize_transaction
    authorize @transaction
  end

  def transaction_params
    params.require(:transaction).permit(
      :invoice_id,
      :student_id,
      :amount,
      :payment_method,
      :transaction_type,
      :transaction_date,
      :reference,
      :notes
    )
  end
end
