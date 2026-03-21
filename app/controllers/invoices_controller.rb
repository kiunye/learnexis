class InvoicesController < ApplicationController
  before_action :set_invoice, only: %i[show edit update destroy download]
  before_action :authorize_invoice, only: %i[show edit update destroy download]

  def index
    authorize Invoice

    scope = policy_scope(Invoice).includes(student: :user)
    @filter_students = policy_scope(Student).includes(:user).joins(:user).order("users.last_name", "users.first_name")

    if params[:status].present? && Invoice.statuses.key?(params[:status])
      scope = scope.where(status: params[:status])
    end

    if params[:student_id].present?
      scope = scope.where(student_id: params[:student_id])
    end

    @pagy, @invoices = pagy(
      scope.order(issue_date: :desc, created_at: :desc),
      limit: 20
    )

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    @invoice_line_items = @invoice.invoice_line_items.includes(fee_assignment: :fee)
  end

  def new
    authorize Invoice
    @invoice = Invoice.new
    @invoice.issue_date = Date.current
    @invoice.due_date = Date.current + 30.days
    @invoice.status = :draft
    @students = policy_scope(Student).includes(:user).order("users.last_name", "users.first_name").joins(:user)
  end

  def create
    authorize Invoice

    @invoice = Invoice.new(invoice_params)

    if @invoice.save
      redirect_to invoice_path(@invoice), notice: "Invoice created successfully."
    else
      @students = policy_scope(Student).includes(:user).order("users.last_name", "users.first_name").joins(:user)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @students = policy_scope(Student).includes(:user).order("users.last_name", "users.first_name").joins(:user)
  end

  def update
    if @invoice.update(invoice_params)
      redirect_to invoice_path(@invoice), notice: "Invoice updated successfully."
    else
      @students = policy_scope(Student).includes(:user).order("users.last_name", "users.first_name").joins(:user)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @invoice.draft? || @invoice.cancelled?
      @invoice.destroy
      redirect_to invoices_path, notice: "Invoice deleted successfully."
    else
      redirect_to invoice_path(@invoice), alert: "Only draft or cancelled invoices can be deleted."
    end
  end

  def bulk_generate
    authorize Invoice
    @students = policy_scope(Student).includes(:user).order("users.last_name", "users.first_name").joins(:user)
  end

  def create_bulk
    authorize Invoice

    issue_date = params[:issue_date].presence && Date.parse(params[:issue_date])
    due_date = params[:due_date].presence && Date.parse(params[:due_date])
    student_ids = params[:student_ids]&.map(&:presence)&.compact&.map(&:to_i) || []

    if issue_date.blank? || due_date.blank?
      redirect_to bulk_generate_invoices_path, alert: "Issue date and due date are required."
      return
    end

    if due_date < issue_date
      redirect_to bulk_generate_invoices_path, alert: "Due date must be on or after issue date."
      return
    end

    service = InvoiceGenerationService.new
    invoices = service.bulk_generate(
      student_ids: student_ids,
      issue_date: issue_date,
      due_date: due_date,
      status: :draft
    )

    if invoices.any?
      redirect_to invoices_path, notice: "#{invoices.size} invoice(s) generated."
    else
      redirect_to bulk_generate_invoices_path, alert: service.errors.presence&.join(" ") || "No invoices generated. Ensure students have pending fee assignments."
    end
  end

  def download
    pdf = InvoicePdfService.build(@invoice)
    send_data pdf,
              filename: "invoice-#{@invoice.id}.pdf",
              type: "application/pdf",
              disposition: "inline"
  end

  private

  def set_invoice
    @invoice = Invoice.find(params[:id])
  end

  def authorize_invoice
    authorize @invoice
  end

  def invoice_params
    params.require(:invoice).permit(
      :student_id,
      :issue_date,
      :due_date,
      :status,
      :notes,
      :total_amount
    )
  end
end
