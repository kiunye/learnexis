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

  def destroy?
    admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.teacher?
        # Teachers see their own classrooms (to be implemented when models exist)
        scope.all
      elsif user.parent?
        # Parents see classrooms of their children (to be implemented when models exist)
        scope.all
      else
        scope.none
      end
    end
  end

  private

  def teaches_classroom?
    # Placeholder - will be implemented when Classroom model exists
    # user.teacher? && record.teacher_id == user.teacher_profile.id
    false
  end
end
