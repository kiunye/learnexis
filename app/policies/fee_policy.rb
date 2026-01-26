class FeePolicy < ApplicationPolicy
  # Placeholder policy - will be extended when Fee model is created in Task 12
  # Based on PRD: All authenticated users can view fees, only admins can manage

  def index?
    true # All authenticated users can view fees
  end

  def show?
    true
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
      # All authenticated users can see fees
      scope.all
    end
  end
end
