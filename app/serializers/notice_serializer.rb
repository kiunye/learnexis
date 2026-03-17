class NoticeSerializer < ActiveModel::Serializer
  attributes :id, :title, :content, :priority, :notice_type, :target_audience,
             :grade_levels, :published_at, :expires_at, :active, :created_at, :updated_at

  # Include author information
  belongs_to :author, serializer: UserSerializer

  # Format timestamps for JavaScript consumption
  def published_at
    object.published_at&.iso8601
  end

  def expires_at
    object.expires_at&.iso8601
  end

  def created_at
    object.created_at.iso8601
  end

  def updated_at
    object.updated_at.iso8601
  end
end
