require "test_helper"

class NoticeTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email_address: "test@example.com", password: "password", password_confirmation: "password", role: :admin)
  end

  test "should not save notice without title" do
    notice = Notice.new(content: "Test content", author: @user)
    assert_not notice.save, "Saved notice without title"
  end

  test "should not save notice without content" do
    notice = Notice.new(title: "Test title", author: @user)
    assert_not notice.save, "Saved notice without content"
  end

  test "should save valid notice" do
    notice = Notice.new(title: "Test title", content: "Test content", author: @user)
    assert notice.save, "Failed to save valid notice"
  end

  test "should have default active status" do
    notice = Notice.new(title: "Test title", content: "Test content", author: @user)
    assert notice.active, "Notice should be active by default"
  end

  test "grade_levels_array should return empty array for empty string" do
    notice = Notice.new(title: "Test", content: "Test", author: @user, grade_levels: "")
    assert_equal [], notice.grade_levels_array
  end

  test "grade_levels_array should parse comma-separated values" do
    notice = Notice.new(title: "Test", content: "Test", author: @user, grade_levels: "1,2,3")
    assert_equal [ 1, 2, 3 ], notice.grade_levels_array
  end

  test "grade_levels_array= should set comma-separated string" do
    notice = Notice.new(title: "Test", content: "Test", author: @user)
    notice.grade_levels_array = [ 1, 2, 3 ]
    assert_equal "1,2,3", notice.grade_levels
  end

  test "active scope should return only active notices" do
    active_notice = Notice.create!(title: "Active", content: "Active", author: @user, active: true, expires_at: 1.day.from_now)
    inactive_notice = Notice.create!(title: "Inactive", content: "Inactive", author: @user, active: false, expires_at: 1.day.from_now)

    assert_includes Notice.active, active_notice
    assert_not_includes Notice.active, inactive_notice
  end

  test "urgent scope should return only urgent notices" do
    urgent_notice = Notice.create!(title: "Urgent", content: "Urgent", author: @user, priority: :urgent, expires_at: 1.day.from_now)
    normal_notice = Notice.create!(title: "Normal", content: "Normal", author: @user, priority: :normal, expires_at: 1.day.from_now)

    assert_includes Notice.urgent, urgent_notice
    assert_not_includes Notice.urgent, normal_notice
  end

  test "for_role scope should return appropriate notices based on user role" do
    # Create notices for different audiences
    all_notice = Notice.create!(title: "For All", content: "For All", author: @user, target_audience: nil, expires_at: 1.day.from_now)
    teacher_notice = Notice.create!(title: "For Teachers", content: "For Teachers", author: @user, target_audience: 0, expires_at: 1.day.from_now)
    parent_notice = Notice.create!(title: "For Parents", content: "For Parents", author: @user, target_audience: 1, expires_at: 1.day.from_now)
    student_notice = Notice.create!(title: "For Students", content: "For Students", author: @user, target_audience: 2, expires_at: 1.day.from_now)
    specific_grades_notice = Notice.create!(title: "For Specific Grades", content: "For Specific Grades", author: @user, target_audience: 3, grade_levels: "1,2,3", expires_at: 1.day.from_now)

    # Admin should see all notices (target_audience: nil, 0, 1, 2, 3)
    assert_equal 5, Notice.for_role(:admin).count

    # Teacher should see all + teacher notices (target_audience: nil, 0)
    assert_equal 2, Notice.for_role(:teacher).count

    # Parent should see all + parent notices (target_audience: nil, 1)
    assert_equal 2, Notice.for_role(:parent).count

    # Student should see all + student notices (target_audience: nil, 2)
    assert_equal 2, Notice.for_role(:student).count
  end

  test "target_audience_symbol returns correct symbols" do
    notice = Notice.new
    notice.target_audience = nil
    assert_equal :all, notice.target_audience_symbol

    notice.target_audience = 0
    assert_equal :teachers, notice.target_audience_symbol

    notice.target_audience = 1
    assert_equal :parents, notice.target_audience_symbol

    notice.target_audience = 2
    assert_equal :students, notice.target_audience_symbol

    notice.target_audience = 3
    assert_equal :specific_grades, notice.target_audience_symbol
  end

  test "target_audience_symbol= sets correct values" do
    notice = Notice.new
    notice.target_audience_symbol = :all
    assert_equal :all, notice.target_audience_symbol

    notice.target_audience_symbol = :teachers
    assert_equal :teachers, notice.target_audience_symbol

    notice.target_audience_symbol = :parents
    assert_equal :parents, notice.target_audience_symbol

    notice.target_audience_symbol = :students
    assert_equal :students, notice.target_audience_symbol

    notice.target_audience_symbol = :specific_grades
    assert_equal :specific_grades, notice.target_audience_symbol
  end

  test "target_audience_symbol persists and round-trips after save" do
    notice = Notice.new(title: "Persist", content: "Content", author: @user, expires_at: 1.day.from_now)
    notice.target_audience_symbol = :teachers
    notice.save!
    notice.reload
    assert_equal :teachers, notice.target_audience_symbol

    notice.target_audience_symbol = :all
    notice.save!
    notice.reload
    assert_equal :all, notice.target_audience_symbol
  end
end
