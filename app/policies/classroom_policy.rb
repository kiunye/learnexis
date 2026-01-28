class ClassroomPolicy < ApplicationPolicy
  # Placeholder policy - will be extended when Classroom model is created in Task 7

  def index?
    admin? || teacher?
  end

  def show?
    admin? || teacher? || parent?
  end

  def create?
    admin?
  end

  def update?
    admin? || (teacher? && teaches_classroom?)
  end

  # Custom member actions
  def enroll_students?
    update?
  end

  def update_enrollment?
    update?
  end

  def destroy?
    admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.teacher?
        # Teachers see their own classrooms
        if user.teacher_profile
          scope.where(class_teacher_id: user.id)
        else
          scope.none
        end
      elsif user.parent?
        # Parents see classrooms of their children
        if user.parent_profile
          scope.joins(:students)
                .joins("INNER JOIN parent_student_relationships ON parent_student_relationships.student_id = students.id")
                .where(parent_student_relationships: { parent_id: user.id })
                .distinct
        else
          scope.none
        end
      else
        scope.none
      end
    end
  end

  private

  def teaches_classroom?
    user.teacher? && record.class_teacher_id == user.id
  end
end
