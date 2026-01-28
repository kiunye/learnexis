require "application_system_test_case"

class DashboardTest < ApplicationSystemTestCase
  test "visiting the sign in page" do
    visit new_session_path
    assert_selector "form"
  end
end
