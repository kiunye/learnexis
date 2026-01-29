class FeesController < ApplicationController
  before_action :set_fee, only: %i[show edit update destroy assign_students update_assignments]
  before_action :authorize_fee, only: %i[show edit update destroy assign_students update_assignments]

  def index
    authorize Fee

    fees_scope = policy_scope(Fee).includes(:fee_assignments)

    if params[:academic_year].present?
      fees_scope = fees_scope.where(academic_year: params[:academic_year])
    else
      fees_scope = fees_scope.where(academic_year: Date.current.year)
    end

    if params[:status].present? && Fee.statuses.key?(params[:status])
      fees_scope = fees_scope.where(status: params[:status])
    end

    if params[:fee_type].present? && Fee.fee_types.key?(params[:fee_type])
      fees_scope = fees_scope.where(fee_type: params[:fee_type])
    end

    @pagy, @fees = pagy(
      fees_scope.order(:fee_type, :name),
      limit: 20
    )

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    @fee_assignments = @fee.fee_assignments
                           .joins(student: :user)
                           .includes(student: :user)
                           .order("users.last_name", "users.first_name")
  end

  def new
    authorize Fee
    @fee = Fee.new
    @fee.academic_year = Date.current.year
    @fee.status = :active
    @fee.fee_type = :tuition
  end

  def create
    authorize Fee

    @fee = Fee.new(fee_params)

    if @fee.save
      redirect_to fee_path(@fee), notice: "Fee created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @fee.update(fee_params)
      redirect_to fee_path(@fee), notice: "Fee updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @fee.fee_assignments.any?
      redirect_to fee_path(@fee), alert: "Cannot delete fee with assignments. Remove assignments first."
    elsif @fee.destroy
      redirect_to fees_path, notice: "Fee deleted successfully."
    else
      redirect_to fee_path(@fee), alert: "Failed to delete fee."
    end
  end

  def assign_students
    # Students not yet assigned to this fee (with classroom for context)
    assigned_ids = @fee.fee_assignments.pluck(:student_id)
    @students = Student.active.includes(:user, :classroom)
                        .where.not(id: assigned_ids)
                        .joins(:user)
                        .order("users.last_name", "users.first_name")
  end

  def update_assignments
    student_ids = params[:student_ids]&.map(&:presence)&.compact&.map(&:to_i) || []

    created = 0
    student_ids.each do |student_id|
      next unless Student.exists?(student_id)
      next if @fee.fee_assignments.exists?(student_id: student_id)

      @fee.fee_assignments.create!(student_id: student_id, status: :pending, installment_count: 1)
      created += 1
    end

    if created.positive?
      redirect_to fee_path(@fee), notice: "#{created} student(s) assigned to fee."
    else
      redirect_to assign_students_fee_path(@fee), alert: "No new students selected or all already assigned."
    end
  end

  private

  def set_fee
    @fee = Fee.find(params[:id])
  end

  def authorize_fee
    authorize @fee
  end

  def fee_params
    params.require(:fee).permit(
      :name,
      :fee_type,
      :amount,
      :academic_year,
      :status,
      :due_date
    )
  end
end
