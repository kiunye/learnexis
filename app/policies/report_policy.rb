class ReportPolicy < ApplicationPolicy
  def index?
    admin? || teacher? || parent?
  end

  def financial?
    admin?
  end

  def attendance?
    admin? || teacher? || parent?
  end

  def transport?
    admin?
  end

  def export?
    admin?
  end
end
