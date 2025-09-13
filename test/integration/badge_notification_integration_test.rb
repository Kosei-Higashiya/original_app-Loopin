require "test_helper"

class BadgeNotificationIntegrationTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "test@example.com",
      password: "password123", 
      password_confirmation: "password123",
      name: "Test User"
    )
    
    @habit = @user.habits.create!(
      name: "Daily Exercise",
      description: "Exercise daily"
    )
    
    # Create a 3-day consecutive badge
    @badge = Badge.create!(
      name: "3日連続",
      description: "3日間連続で記録",
      condition_type: "consecutive_days",
      condition_value: 3,
      active: true,
      icon: "🔥"
    )
    
    sign_in @user
  end

  test "badge notification appears after earning consecutive days badge" do
    # Create 3 consecutive days of records via the API
    3.times do |i|
      date = Date.current - i.days
      post habit_toggle_record_for_date_path(@habit), 
           params: { date: date.to_s }, 
           as: :json
      assert_response :success
    end
    
    # Navigate to a page that would trigger the notification display
    get habits_path
    assert_response :success
    
    # Check if the badge notification appears in the response
    assert_select '.alert-success', text: /バッジ.*3日連続.*を獲得/
  end

  test "badge notification does not appear twice on subsequent page visits" do
    # Create records and earn badge
    3.times do |i|
      date = Date.current - i.days
      post habit_toggle_record_for_date_path(@habit), 
           params: { date: date.to_s }, 
           as: :json
    end
    
    # First page visit - should show badge notification
    get habits_path
    assert_response :success
    assert_select '.alert-success', text: /バッジ.*を獲得/
    
    # Second page visit - should NOT show badge notification again
    get dashboard_path  
    assert_response :success
    
    # Should not have any badge-related success flash messages
    response_body = response.body
    badge_notifications = response_body.scan(/バッジ.*を獲得/)
    assert_equal 0, badge_notifications.count, "Badge notification should not appear on second page visit"
  end

  test "ajax requests do not trigger badge notifications" do
    # Create records and earn badge
    3.times do |i|
      date = Date.current - i.days
      post habit_toggle_record_for_date_path(@habit), 
           params: { date: date.to_s }, 
           as: :json
    end
    
    # Make an AJAX request - should not show notifications
    get habits_path, headers: { 'X-Requested-With' => 'XMLHttpRequest' }
    assert_response :success
    
    # Badge should still be in session for future non-AJAX requests
    get habits_path  # Non-AJAX request 
    assert_response :success
    assert_select '.alert-success', text: /バッジ.*を獲得/
  end

  private

  def habit_toggle_record_for_date_path(habit)
    "/habits/#{habit.id}/toggle_record_for_date"
  end

  def dashboard_path
    "/"  # Assuming root is dashboard
  end
end