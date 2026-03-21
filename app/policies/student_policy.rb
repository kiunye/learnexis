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
        scope.joins(:classroom).where(classrooms: { class_teacher_id: user.id })
      elsif user.parent?
        scope.joins(:parent_student_relationships)
              .where(parent_student_relationships: { parent_id: user.id })
      else
        scope.none
      end
    end
  end

  private

  def owns_student?
    user.parent? && record.parents.exists?(id: user.id)
  end

  def teaches_student?
    return false unless user.teacher? && record.classroom

    record.classroom.class_teacher_id == user.id
  end
end
