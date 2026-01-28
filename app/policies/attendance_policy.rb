class AttendancePolicy < ApplicationPolicy
  def index?
    admin? || teacher? || parent?
  end

  def mark?
    admin? || (teacher? && teaches_classroom?)
  end

  def update?
    mark?
  end

  def reports?
    admin? || teacher? || parent?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.teacher?
        scope.joins(:classroom).where(classrooms: { class_teacher_id: user.id })
      elsif user.parent?
        scope.joins(:student)
              .joins("INNER JOIN parent_student_relationships ON parent_student_relationships.student_id = students.id")
              .where(parent_student_relationships: { parent_id: user.id })
              .distinct
      else
        scope.none
      end
    end
  end

  private

  def teaches_classroom?
    return false unless record.respond_to?(:classroom) && record.classroom
    record.classroom.class_teacher_id == user.id
  end
end
