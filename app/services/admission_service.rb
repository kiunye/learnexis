class AdmissionService
  attr_reader :errors

  def initialize
    @errors = []
  end

  # Create a new student admission with user account and optional parent linking
  # @param student_params [Hash] Student attributes (date_of_birth, admission_date, etc.)
  # @param user_params [Hash] User attributes (email_address, first_name, last_name, phone_number, password)
  # @param parent_ids [Array<Integer>] Optional array of parent user IDs to link
  # @param classroom_id [Integer] Optional classroom ID
  # @param transport_route_id [Integer] Optional transport route ID
  # @return [Student, nil] Created student or nil if failed
  def create_admission(student_params:, user_params:, parent_ids: [], classroom_id: nil, transport_route_id: nil)
    ActiveRecord::Base.transaction do
      # Generate admission number
      admission_number = generate_admission_number

      # Create user account
      user = User.new(
        email_address: user_params[:email_address],
        first_name: user_params[:first_name],
        last_name: user_params[:last_name],
        phone_number: user_params[:phone_number],
        password: user_params[:password] || SecureRandom.hex(8),
        password_confirmation: user_params[:password_confirmation] || user_params[:password] || SecureRandom.hex(8),
        role: :student
      )

      unless user.save
        @errors.concat(user.errors.full_messages)
        raise ActiveRecord::Rollback
      end

      # Create student record
      student = Student.new(
        admission_number: admission_number,
        date_of_birth: student_params[:date_of_birth],
        admission_date: student_params[:admission_date] || Date.current,
        status: :active,
        medical_conditions: student_params[:medical_conditions],
        allergies: student_params[:allergies],
        special_needs: student_params[:special_needs],
        emergency_contact_name: student_params[:emergency_contact_name],
        emergency_contact_phone: student_params[:emergency_contact_phone],
        blood_group: student_params[:blood_group],
        user: user,
        classroom_id: classroom_id,
        transport_route_id: transport_route_id
      )

      unless student.save
        @errors.concat(student.errors.full_messages)
        raise ActiveRecord::Rollback
      end

      # Link parents if provided
      if parent_ids.any?
        parent_ids.each do |parent_id|
          parent = User.find_by(id: parent_id, role: :parent)
          next unless parent

          ParentStudentRelationship.find_or_create_by!(
            parent: parent,
            student: student,
            relationship_type: "parent"
          )
        end
      end

      student
    end
  rescue ActiveRecord::RecordInvalid => e
    @errors << e.message
    nil
  rescue StandardError => e
    @errors << e.message
    nil
  end

  # Generate unique admission number
  # Format: ADM{YYYY}{NNN} (e.g., ADM2025001)
  def generate_admission_number
    year = Date.current.year
    prefix = "ADM#{year}"

    # Find the last admission number for this year
    last_student = Student.where("admission_number LIKE ?", "#{prefix}%")
                          .order(admission_number: :desc)
                          .first

    if last_student
      # Extract the number part and increment
      last_number = last_student.admission_number.scan(/\d+$/).first.to_i
      new_number = last_number + 1
    else
      new_number = 1
    end

    # Format with leading zeros (3 digits)
    "#{prefix}#{new_number.to_s.rjust(3, '0')}"
  end

  # Update student admission (for editing)
  def update_admission(student:, student_params:, user_params: {}, parent_ids: nil)
    ActiveRecord::Base.transaction do
      # Update user if params provided
      if user_params.present?
        student.user.update(user_params)
        unless student.user.valid?
          @errors.concat(student.user.errors.full_messages)
          raise ActiveRecord::Rollback
        end
      end

      # Update student
      unless student.update(student_params)
        @errors.concat(student.errors.full_messages)
        raise ActiveRecord::Rollback
      end

      # Update parent relationships if provided
      if parent_ids
        # Remove existing relationships not in the new list
        student.parent_student_relationships.where.not(parent_id: parent_ids).destroy_all

        # Add new relationships
        parent_ids.each do |parent_id|
          parent = User.find_by(id: parent_id, role: :parent)
          next unless parent

          ParentStudentRelationship.find_or_create_by!(
            parent: parent,
            student: student,
            relationship_type: "parent"
          )
        end
      end

      student
    end
  rescue ActiveRecord::RecordInvalid => e
    @errors << e.message
    nil
  rescue StandardError => e
    @errors << e.message
    nil
  end

  def success?
    @errors.empty?
  end
end
