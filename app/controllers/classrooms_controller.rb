class ClassroomsController < ApplicationController
  before_action :set_classroom, only: %i[show edit update destroy enroll_students update_enrollment]
  before_action :authorize_classroom, only: %i[show edit update destroy enroll_students update_enrollment]

  def index
    authorize Classroom

    classrooms_scope = policy_scope(Classroom).includes(:class_teacher, :students)

    # Apply academic year filter
    if params[:academic_year].present?
      classrooms_scope = classrooms_scope.where(academic_year: params[:academic_year])
    else
      # Default to current year
      classrooms_scope = classrooms_scope.where(academic_year: Date.current.year)
    end

    # Apply grade level filter
    if params[:grade_level].present?
      classrooms_scope = classrooms_scope.where(grade_level: params[:grade_level])
    end

    # Apply search filter
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      classrooms_scope = classrooms_scope.where("name ILIKE ? OR room_number ILIKE ?", search_term, search_term)
    end

    @pagy, @classrooms = pagy(
      classrooms_scope.order(:grade_level, :section),
      limit: 20
    )

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    @students = @classroom.students.includes(:user).order(:created_at)
  end

  def new
    authorize Classroom
    @classroom = Classroom.new
    @classroom.academic_year = Date.current.year
    @teachers = User.where(role: :teacher).order(:first_name, :last_name)
  end

  def create
    authorize Classroom

    @classroom = Classroom.new(classroom_params)
    @teachers = User.where(role: :teacher).order(:first_name, :last_name)

    if @classroom.save
      redirect_to classroom_path(@classroom), notice: "Classroom created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @teachers = User.where(role: :teacher).order(:first_name, :last_name)
  end

  def update
    @teachers = User.where(role: :teacher).order(:first_name, :last_name)

    if @classroom.update(classroom_params)
      redirect_to classroom_path(@classroom), notice: "Classroom updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @classroom.students.any?
      redirect_to classrooms_path, alert: "Cannot delete classroom with students. Please reassign students first."
    elsif @classroom.destroy
      redirect_to classrooms_path, notice: "Classroom deleted successfully."
    else
      redirect_to classroom_path(@classroom), alert: "Failed to delete classroom."
    end
  end

  def enroll_students
    # Get all students not in this classroom
    @available_students = Student.includes(:user, :classroom)
                                  .where.not(id: @classroom.students.pluck(:id))
                                  .or(Student.where(classroom_id: nil))
                                  .order("users.first_name, users.last_name")
                                  .joins(:user)
  end

  def update_enrollment
    student_ids = params[:student_ids] || []

    # Validate capacity
    new_count = student_ids.size
    current_count = @classroom.students.count
    if (current_count + new_count) > @classroom.capacity
      redirect_to classroom_path(@classroom), alert: "Cannot enroll students. Classroom capacity would be exceeded."
      return
    end

    # Update student enrollments
    if student_ids.any?
      Student.where(id: student_ids).update_all(classroom_id: @classroom.id)
      redirect_to classroom_path(@classroom), notice: "#{student_ids.size} student(s) enrolled successfully."
    else
      redirect_to classroom_path(@classroom), alert: "No students selected."
    end
  end

  private

  def set_classroom
    @classroom = Classroom.find(params[:id])
  end

  def authorize_classroom
    authorize @classroom
  end

  def classroom_params
    params.require(:classroom).permit(
      :name,
      :grade_level,
      :section,
      :academic_year,
      :capacity,
      :room_number,
      :class_teacher_id
    )
  end
end
