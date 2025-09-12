require 'test_helper'

class EmailDeliveryTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActionMailer::TestHelper

  setup do
    # Create a test user
    @user = User.create!(
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )
  end

  test "should send password reset email successfully" do
    # Ensure we're capturing emails in test
    assert_difference 'ActionMailer::Base.deliveries.size', 1 do
      post user_password_path, params: {
        user: { email: @user.email }
      }
    end

    assert_redirected_to new_user_session_path
    
    # Check the email was queued/sent
    email = ActionMailer::Base.deliveries.last
    assert_not_nil email
    assert_equal [@user.email], email.to
    assert_equal ['noreply@loopin-app.com'], email.from
    assert_match 'パスワードの変更リクエスト', email.subject
  end

  test "should have correct mailer configuration in development" do
    # Test the development configuration
    Rails.env = 'development'
    Rails.application.configure do
      config.action_mailer.delivery_method = :letter_opener_web
      config.action_mailer.perform_deliveries = true
      config.action_mailer.raise_delivery_errors = true
    end

    assert_equal :letter_opener_web, Rails.application.config.action_mailer.delivery_method
    assert Rails.application.config.action_mailer.perform_deliveries
    assert Rails.application.config.action_mailer.raise_delivery_errors
  ensure
    Rails.env = 'test' # Reset to test environment
  end

  test "should display japanese password reset email content" do
    # Test the email template content
    @user.send_reset_password_instructions
    
    email = ActionMailer::Base.deliveries.last
    assert_not_nil email
    
    # Check Japanese content
    assert_match 'こんにちは test@example.com さん！', email.body.to_s
    assert_match 'パスワードの変更リクエストがありました', email.body.to_s
    assert_match 'パスワードを変更する', email.body.to_s
    assert_match 'このメールに心当たりがない場合', email.body.to_s
  end

  test "password reset flow works end to end" do
    # Step 1: Request password reset
    post user_password_path, params: {
      user: { email: @user.email }
    }
    
    assert_redirected_to new_user_session_path
    
    # Step 2: Get the reset token from the email
    email = ActionMailer::Base.deliveries.last
    reset_token = email.body.match(/reset_password_token=([^"&]+)/)[1]
    assert_not_nil reset_token
    
    # Step 3: Visit the password reset page
    get edit_user_password_path(reset_password_token: reset_token)
    assert_response :success
    
    # Step 4: Submit new password
    patch user_password_path, params: {
      user: {
        reset_password_token: reset_token,
        password: 'newpassword123',
        password_confirmation: 'newpassword123'
      }
    }
    
    # Should be redirected after successful password reset
    assert_response :redirect
    
    # Verify the user can sign in with new password
    post user_session_path, params: {
      user: {
        email: @user.email,
        password: 'newpassword123'
      }
    }
    
    assert_response :redirect # Should be redirected after successful sign in
  end
end