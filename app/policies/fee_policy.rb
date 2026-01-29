class FeePolicy < ApplicationPolicy
  # All authenticated users can view fees; only admins can manage.

  def index?
    true
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

  def assign_students?
    admin?
  end

  def update_assignments?
    admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
