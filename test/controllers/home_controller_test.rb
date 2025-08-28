require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_path
    assert_response :success
  end

  test "should get dashboard" do
    get dashboard_path
    assert_response :success
    assert_select "h1", "ダッシュボード"
    assert_select ".dashboard-card", count: 4
  end
end
