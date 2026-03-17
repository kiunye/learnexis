class Notice < ApplicationRecord
  # Enums - using array syntax to let Rails assign values and avoid conflicts
  enum :priority, [ :low, :normal, :urgent ]
  enum :notice_type, [ :academic, :administrative, :emergency, :grade_specific ]
  # Avoid using 'all' as it conflicts with ActiveRecord::Relation#all
  enum :target_audience, [ :teachers, :parents, :students, :specific_grades ]
  # We'll handle 'all' case differently in scopes (by setting target_audience to nil)

  # Associations
  belongs_to :author, class_name: "User"
  has_many_attached :attachments

  # Validations
  validates :title, :content, presence: true
  validates :expires_at, comparison: { greater_than: :published_at }, if: -> { expires_at.present? && published_at.present? }

  # Scopes
  scope :active, -> { where(active: true).where("expires_at > ?", Time.current) }
  scope :urgent, -> { where(priority: :urgent) }
  scope :for_role, ->(role) {
    case role.to_sym
    when :admin
      # Admin sees all notices (including those with target_audience: nil for 'all')
      where(target_audience: [ nil, 0, 1, 2, 3 ]) # nil represents 'all', 0:teachers, 1:parents, 2:students, 3:specific_grades
    when :teacher
      where(target_audience: [ nil, 0 ]) # nil or teachers
    when :parent
      where(target_audience: [ nil, 1 ]) # nil or parents
    when :student
      where(target_audience: [ nil, 2 ]) # nil or students
    else
      where(target_audience: [ nil ]) # only 'all' notices
    end
  }

  # Grade-specific scope
  scope :for_grade, ->(grade) {
    where(target_audience: :specific_grades).where("grade_levels LIKE ?", "%#{grade}%")
  }

  # Callbacks for real-time updates via Action Cable
  after_create :broadcast_create
  after_update :broadcast_update
  after_destroy :broadcast_destroy

  # Instance methods
  def active_and_not_expired?
    active? && (!expires_at? || expires_at.future?)
  end

  # Returns target_audience as symbol (including :all for nil)
  def target_audience_symbol
    raw = self[:target_audience]
    case raw
    when nil then :all
    when 0, "teachers" then :teachers
    when 1, "parents" then :parents
    when 2, "students" then :students
    when 3, "specific_grades" then :specific_grades
    else :all
    end
  end

  # Sets target_audience from symbol
  def target_audience_symbol=(symbol)
    self[:target_audience] = case symbol
    when :all then nil
    when :teachers then 0
    when :parents then 1
    when :students then 2
    when :specific_grades then 3
    else nil
    end
  end

  # Returns grade_levels as array of integers
  def grade_levels_array
    grade_levels.to_s.split(",").map(&:strip).map(&:to_i).reject(&:zero?)
  end

  # Sets grade_levels from array of integers
  def grade_levels_array=(levels)
    self.grade_levels = levels.reject(&:zero?).map(&:to_s).join(",")
  end

  private

  def broadcast_create
    NoticeChannel.broadcast_create(self)
  end

  def broadcast_update
    NoticeChannel.broadcast_update(self)
  end

  def broadcast_destroy
    NoticeChannel.broadcast_destroy(id)
  end
end
