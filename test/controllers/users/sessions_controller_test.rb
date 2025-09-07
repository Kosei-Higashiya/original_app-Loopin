require "test_helper"

class Users::SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "should logout and redirect to root path" do
    sign_in @user
    
    # Perform logout
    delete destroy_user_session_path
    
    # Should redirect to root path
    assert_redirected_to root_path
    
    # Follow redirect to verify it works
    follow_redirect!
    assert_response :success
  end

  test "should allow logout without authentication" do
    # Try to logout without being signed in (should not raise error)
    delete destroy_user_session_path
    
    # Should redirect to root path
    assert_redirected_to root_path
  end
end