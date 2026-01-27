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
        # Teachers see students in their classrooms
        if user.teacher_profile
          scope.joins(:classroom).where(classrooms: { class_teacher_id: user.id })
        else
          scope.none
        end
      elsif user.parent?
        # Parents see only their children
        if user.parent_profile
          scope.joins(:parent_student_relationships)
                .where(parent_student_relationships: { parent_id: user.id })
        else
          scope.none
        end
      else
        scope.none
      end
    end
  end

  private

  def owns_student?
    user.parent? && user.parent_profile&.students&.include?(record)
  end

  def teaches_student?
    return false unless user.teacher? && record.classroom

    record.classroom.class_teacher_id == user.id
  end
end
