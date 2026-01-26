class NoticePolicy < ApplicationPolicy
  # Placeholder policy - will be extended when Notice model is created in Task 15

  def index?
    true # All authenticated users can view notices
  end

  def show?
    true
  end

  def create?
    admin? || teacher?
  end

  def update?
    admin? || (teacher? && created_notice?)
  end

  def destroy?
    admin? || (teacher? && created_notice?)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      # All authenticated users can see notices (filtered by audience in model)
      scope.all
    end
  end

  private

  def created_notice?
    # Placeholder - will be implemented when Notice model exists
    # user.teacher? && record.created_by_id == user.id
    false
  end
end
