require "test_helper"

class BadgeNotificationsTest < ActiveSupport::TestCase
  include BadgeNotifications

  def setup
    @session = {}
    @request = Minitest::Mock.new
    @flash = {}
  end

  # Mock the session method to return our test session
  def session
    @session
  end

  # Mock the request method
  def request
    @request
  end

  # Mock the flash method
  def flash
    @flash
  end

  test "set_badge_notification prevents duplicates" do
    badge1 = Badge.new(id: 1, name: "Test Badge 1")
    badge2 = Badge.new(id: 2, name: "Test Badge 2") 
    badge1_duplicate = Badge.new(id: 1, name: "Test Badge 1")

    # Set initial badges
    set_badge_notification([badge1, badge2])
    assert_equal 2, session[:newly_earned_badges].count

    # Try to add duplicate - should be ignored
    set_badge_notification([badge1_duplicate])
    assert_equal 2, session[:newly_earned_badges].count
    
    # Add new badge - should be added
    badge3 = Badge.new(id: 3, name: "Test Badge 3")
    set_badge_notification([badge3])
    assert_equal 3, session[:newly_earned_badges].count
  end

  test "get_and_clear_badge_notifications clears session properly" do
    badge = Badge.new(id: 1, name: "Test Badge")
    set_badge_notification([badge])
    
    # Verify badge is in session
    assert_equal 1, session[:newly_earned_badges].count
    
    # Clear and get notifications
    notifications = get_and_clear_badge_notifications
    
    # Verify notifications returned and session cleared
    assert_equal 1, notifications.count
    assert_equal "Test Badge", notifications.first['name']
    assert_nil session[:newly_earned_badges]
  end

  test "set_badge_notification_flash skips when flash already contains badge message" do
    badge = Badge.new(id: 1, name: "Test Badge")
    set_badge_notification([badge])
    
    # Set up mocks
    @request.expect(:format, double_mock = Minitest::Mock.new)
    double_mock.expect(:turbo_stream?, false)
    @request.expect(:xhr?, false)
    
    # Pre-set a badge-related flash message
    @flash[:success] = "🎉おめでとうございます! バッジ「Other Badge」を獲得しました！"
    
    set_badge_notification_flash
    
    # Flash should remain unchanged (not overwritten)
    assert_equal "🎉おめでとうございます! バッジ「Other Badge」を獲得しました！", @flash[:success]
    
    @request.verify
    double_mock.verify
  end

  test "set_badge_notification_flash skips for xhr requests" do
    badge = Badge.new(id: 1, name: "Test Badge")
    set_badge_notification([badge])
    
    # Mock XHR request
    @request.expect(:format, double_mock = Minitest::Mock.new)
    double_mock.expect(:turbo_stream?, false)
    @request.expect(:xhr?, true)
    
    set_badge_notification_flash
    
    # Flash should be empty for XHR requests
    assert_empty @flash
    # Session should still contain the badge (not cleared for XHR)
    assert_equal 1, session[:newly_earned_badges].count
    
    @request.verify 
    double_mock.verify
  end
end