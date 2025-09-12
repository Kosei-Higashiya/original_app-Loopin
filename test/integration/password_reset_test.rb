require 'test_helper'

class PasswordResetTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one) # Assumes a user fixture exists
  end

  test "should display password reset request form" do
    get new_user_password_path
    assert_response :success
    assert_select "h1", text: "🔑 パスワード再設定"
    assert_select "input[name='user[email]']"
    assert_select "input[type=submit][value='パスワード再設定メールを送信']"
  end

  test "should have letter opener web route in development" do
    # This test verifies the route is configured, but won't work in test env
    # since the route is development-only
    if Rails.env.development?
      get "/letter_opener"
      assert_response :success
    else
      # In test environment, the route shouldn't exist
      assert_raises(ActionController::RoutingError) do
        get "/letter_opener"
      end
    end
  end

  test "should have proper action mailer configuration for letter opener web" do
    # Verify the configuration is set in development
    if Rails.env.development?
      assert_equal :letter_opener_web, Rails.application.config.action_mailer.delivery_method
      assert Rails.application.config.action_mailer.perform_deliveries
    end
  end

  test "should have proper devise mailer sender configuration" do
    assert_equal 'noreply@loopin-app.com', Devise.mailer_sender
  end
end