class Transport::AssignmentPolicy < ApplicationPolicy
  def index?
    admin?
  end

  def assign_student?
    admin?
  end

  def unassign_student?
    admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
