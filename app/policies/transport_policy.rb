class TransportPolicy < ApplicationPolicy
  def route?
    admin?
  end

  def bus?
    admin?
  end

  def assignment?
    admin?
  end
end
