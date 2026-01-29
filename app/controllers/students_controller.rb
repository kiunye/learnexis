class StudentsController < ApplicationController
  before_action :set_student, only: %i[show edit update destroy]
  before_action :authorize_student, only: %i[show edit update destroy]

  def index
    authorize Student

    # Start with base scope
    students_scope = policy_scope(Student).includes(:user, :classroom)

    # Apply search filter
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      students_scope = students_scope.joins(:user)
                                     .where(
                                       "users.first_name ILIKE ? OR users.last_name ILIKE ? OR students.admission_number ILIKE ?",
                                       search_term, search_term, search_term
                                     )
    end

    # Apply status filter
    if params[:status].present? && Student.statuses.key?(params[:status])
      students_scope = students_scope.where(status: params[:status])
    end

    # Apply classroom filter
    if params[:classroom_id].present?
      students_scope = students_scope.where(classroom_id: params[:classroom_id])
    end

    # Order and paginate
    @pagy, @students = pagy(
      students_scope.order(created_at: :desc),
      limit: 20
    )

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    @student = Student.includes(:user, :classroom, :parents).find(params[:id])
    authorize @student
  end

  def new
    authorize Student
    @admission_service = AdmissionService.new
    @classrooms = Classroom.order(:grade_level, :section)
    @parents = User.where(role: :parent).order(:first_name, :last_name)
  end

  def create
    authorize Student

    @admission_service = AdmissionService.new
    @classrooms = Classroom.order(:grade_level, :section)
    @parents = User.where(role: :parent).order(:first_name, :last_name)

    # Handle photo upload if present
    photo_params = params[:student][:photo] if params[:student] && params[:student][:photo]

    student = @admission_service.create_admission(
      student_params: student_params,
      user_params: user_params,
      parent_ids: params[:parent_ids] || [],
      classroom_id: params[:student][:classroom_id].presence
    )

    if @admission_service.success? && student
      # Attach photo if provided
      if photo_params
        student.photo.attach(photo_params)
      end

      redirect_to student_path(student), notice: "Student admission created successfully."
    else
      @errors = @admission_service.errors
      @student = student if student
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @admission_service = AdmissionService.new
    @classrooms = Classroom.order(:grade_level, :section)
    @parents = User.where(role: :parent).order(:first_name, :last_name)
    @selected_parent_ids = @student.parents.pluck(:id)
  end

  def update
    @admission_service = AdmissionService.new
    @classrooms = Classroom.order(:grade_level, :section)
    @parents = User.where(role: :parent).order(:first_name, :last_name)

    # Handle photo upload if present
    photo_params = params[:student][:photo] if params[:student] && params[:student][:photo]

    updated_student = @admission_service.update_admission(
      student: @student,
      student_params: student_params,
      user_params: user_params.except(:password, :password_confirmation).compact,
      parent_ids: params[:parent_ids] || []
    )

    if @admission_service.success? && updated_student
      # Attach photo if provided
      if photo_params
        @student.photo.attach(photo_params)
      end

      redirect_to student_path(@student), notice: "Student updated successfully."
    else
      @errors = @admission_service.errors
      @selected_parent_ids = params[:parent_ids] || []
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Soft delete: change status to inactive
    if @student.update(status: :inactive)
      redirect_to students_path, notice: "Student deactivated successfully."
    else
      redirect_to student_path(@student), alert: "Failed to deactivate student."
    end
  end

  private

  def set_student
    @student = Student.find(params[:id])
  end

  def authorize_student
    authorize @student
  end

  def student_params
    params.require(:student).permit(
      :date_of_birth,
      :admission_date,
      :medical_conditions,
      :allergies,
      :special_needs,
      :emergency_contact_name,
      :emergency_contact_phone,
      :blood_group,
      :classroom_id,
      :photo
    )
  end

  def user_params
    params.require(:user).permit(
      :email_address,
      :first_name,
      :last_name,
      :phone_number,
      :password,
      :password_confirmation
    )
  end
end
