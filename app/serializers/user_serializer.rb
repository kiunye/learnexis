class UserSerializer < ActiveModel::Serializer
  attributes :id, :email_address, :first_name, :last_name, :role

  def full_name
    "#{object.first_name} #{object.last_name}".strip
  end
end
