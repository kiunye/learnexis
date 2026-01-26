class StudentPolicy < ApplicationPolicy
  # Placeholder policy - will be extended when Student model is created in Task 7
  # Based on PRD expectations:
  # - Admins and teachers can list students
  # - Admins, teachers, and parents (of the student) can view
  # - Only admins can create
  # - Admins and teachers (who teach the student) can update

  def index?
    admin? || teacher?
  end

  def show?
    admin? || teacher? || owns_student?
  end

  def create?
    admin?
  end

  def update?
    admin? || (teacher? && teaches_student?)
  end

  def destroy?
    admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.teacher?
        # Teachers see students in their classrooms (to be implemented when models exist)
        scope.all
      elsif user.parent?
        # Parents see only their children (to be implemented when models exist)
        scope.none
      else
        scope.none
      end
    end
  end

  private

  def owns_student?
    # Placeholder - will be implemented when ParentProfile and relationships exist
    # user.parent? && user.parent_profile.students.include?(record)
    false
  end

  def teaches_student?
    # Placeholder - will be implemented when Classroom and enrollment models exist
    # user.teacher? && record.classrooms.exists?(teacher_id: user.teacher_profile.id)
    false
  end
end
