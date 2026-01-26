class InvoicePolicy < ApplicationPolicy
  # Placeholder policy - will be extended when Invoice model is created in Task 13

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

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.teacher?
        # Teachers see invoices for students in their classrooms (to be implemented)
        scope.all
      elsif user.parent?
        # Parents see invoices for their children (to be implemented)
        scope.all
      else
        scope.none
      end
    end
  end

  private

  def owns_invoice?
    # Placeholder - will be implemented when Invoice model exists
    # user.parent? && record.student.parents.include?(user.parent_profile)
    false
  end
end
