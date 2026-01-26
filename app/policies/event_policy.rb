class EventPolicy < ApplicationPolicy
  # Placeholder policy - will be extended when Event model is created in Task 16

  def index?
    true # All authenticated users can view events
  end

  def show?
    true
  end

  def create?
    admin? || teacher?
  end

  def update?
    admin? || (teacher? && created_event?)
  end

  def destroy?
    admin? || (teacher? && created_event?)
  end

  def register?
    true # All authenticated users can register for events (subject to audience rules)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      # All authenticated users can see events (filtered by audience in model)
      scope.all
    end
  end

  private

  def created_event?
    # Placeholder - will be implemented when Event model exists
    # user.teacher? && record.created_by_id == user.id
    false
  end
end
