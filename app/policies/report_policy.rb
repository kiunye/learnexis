class ReportPolicy < ApplicationPolicy
  def financial?
    admin?
  end

  def attendance?
    admin? || teacher?
  end

  def transport?
    admin?
  end

  def export?
    admin?
  end
end
