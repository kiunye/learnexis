class InvoicePolicy < ApplicationPolicy
  def index?
    admin? || teacher? || parent?
  end

  def show?
    admin? || teacher? || owns_invoice?
  end

  def create?
    admin?
  end

  def update?
    admin?
  end

  def destroy?
    admin?
  end

  def bulk_generate?
    admin?
  end

  def download?
    show?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.teacher?
        scope.joins(student: :classroom)
             .where(classrooms: { class_teacher_id: user.id })
      elsif user.parent?
        scope.joins(student: :parent_student_relationships)
             .where(parent_student_relationships: { parent_id: user.id })
      else
        scope.none
      end
    end
  end

  private

  def owns_invoice?
    return false unless user.parent?
    record.student.parents.include?(user)
  end
end
