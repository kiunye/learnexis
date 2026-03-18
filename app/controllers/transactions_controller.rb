class TransactionsController < ApplicationController
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

    # M-Pesa Callback
    def mpesa_callback
      # In production, this would be a webhook endpoint for M-Pesa provider
      # For now, we'll simulate handling the callback

      callback_data = params.except(:controller, :action, :format).to_unsafe_h

      # Process the callback through our service
      result = MpesaPaymentService.process_callback(callback_data)

      if result[:success] && result[:data].present?
        # Record the transaction
        transaction = MpesaPaymentService.record_transaction(result[:data])

        if transaction.present?
          # Send confirmation SMS/SMS to parents
          # SmsService.send_payment_confirmation(transaction) # Would implement this

          render json: { success: true, message: "M-Pesa payment processed successfully" }, status: :ok
        else
          render json: { success: false, error: "Failed to record transaction" }, status: :unprocessable_entity
        end
      else
        render json: { success: false, error: result[:error] || "Invalid callback data" }, status: :unprocessable_entity
      end
    end

    # Verify M-Pesa transaction status
    def verify_mpesa
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
    send_data pdf.render,
              filename: "receipt-#{@transaction.id}.pdf",
              type: "application/pdf",
              disposition: "inline"
  end

  private

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
