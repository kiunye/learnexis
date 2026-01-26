class TransactionPolicy < ApplicationPolicy
  # Placeholder policy - will be extended when Transaction model is created in Task 14

  def index?
    admin? || teacher? || parent?
  end

  def show?
    admin? || teacher? || owns_transaction?
  end

  def create?
    admin? || parent? # Parents can make payments
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
        # Teachers see transactions for students in their classrooms (to be implemented)
        scope.all
      elsif user.parent?
        # Parents see their own transactions (to be implemented)
        scope.all
      else
        scope.none
      end
    end
  end

  private

  def owns_transaction?
    # Placeholder - will be implemented when Transaction model exists
    # user.parent? && record.payer_id == user.parent_profile.id
    false
  end
end
