require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index without authentication" do
    get root_path
    assert_response :success
  end

  test "should get dashboard with authentication" do
    sign_in users(:one)
    get dashboard_path
    assert_response :success
  end

  test "should redirect to login when accessing dashboard without authentication" do
    get dashboard_path
    assert_redirected_to new_user_session_path
  end
end
