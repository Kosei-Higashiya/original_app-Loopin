require 'test_helper'

class BadgeNotificationsTest < ActionDispatch::IntegrationTest
  class TestController < ApplicationController
    include BadgeNotifications
    
    # Allow testing private methods
    public :set_badge_notification, :get_and_clear_badge_notifications, :set_badge_notification_flash
  end

  setup do
    @controller = TestController.new
    @request = ActionDispatch::TestRequest.new
    @controller.request = @request
    @controller.session = ActionDispatch::Request::Session.create(@request.session_store, @request, {})
    
    # Create test badges
    @badge1 = Badge.create!(name: "Test Badge 1", description: "Test", condition_type: "consecutive_days", condition_value: 3)
    @badge2 = Badge.create!(name: "Test Badge 2", description: "Test", condition_type: "total_days", condition_value: 10)
  end

  teardown do
    Badge.destroy_all
  end

  test "set_badge_notification should add badges to session" do
    badges = [@badge1, @badge2]
    @controller.set_badge_notification(badges)
    
    assert_equal 2, @controller.session[:newly_earned_badges].length
    assert_includes @controller.session[:newly_earned_badges].map { |b| b['name'] }, "Test Badge 1"
    assert_includes @controller.session[:newly_earned_badges].map { |b| b['name'] }, "Test Badge 2"
  end

  test "set_badge_notification should prevent duplicate badges" do
    # Add same badge twice
    @controller.set_badge_notification([@badge1])
    @controller.set_badge_notification([@badge1])
    
    # Should only have one instance in session
    assert_equal 1, @controller.session[:newly_earned_badges].length
    assert_equal "Test Badge 1", @controller.session[:newly_earned_badges].first['name']
  end

  test "set_badge_notification should allow different badges" do
    @controller.set_badge_notification([@badge1])
    @controller.set_badge_notification([@badge2])
    
    # Should have both badges
    assert_equal 2, @controller.session[:newly_earned_badges].length
    badge_names = @controller.session[:newly_earned_badges].map { |b| b['name'] }
    assert_includes badge_names, "Test Badge 1"
    assert_includes badge_names, "Test Badge 2"
  end

  test "get_and_clear_badge_notifications should return and clear session" do
    @controller.set_badge_notification([@badge1, @badge2])
    
    # Get and clear
    notifications = @controller.get_and_clear_badge_notifications
    
    # Should return the notifications
    assert_equal 2, notifications.length
    assert_includes notifications.map { |n| n['name'] }, "Test Badge 1"
    assert_includes notifications.map { |n| n['name'] }, "Test Badge 2"
    
    # Session should be cleared
    assert_nil @controller.session[:newly_earned_badges]
  end

  test "get_and_clear_badge_notifications should return empty array when no notifications" do
    notifications = @controller.get_and_clear_badge_notifications
    assert_equal [], notifications
  end

  test "set_badge_notification_flash should set flash message and clear session" do
    @controller.set_badge_notification([@badge1])
    
    # Mock flash to capture messages  
    flash_messages = {}
    @controller.define_singleton_method(:flash) { flash_messages }
    
    @controller.set_badge_notification_flash
    
    # Should set flash message
    assert_match /Test Badge 1/, flash_messages[:success]
    assert_match /おめでとうございます/, flash_messages[:success]
    
    # Session should be cleared
    assert_nil @controller.session[:newly_earned_badges]
  end

  test "set_badge_notification_flash should handle multiple badges" do
    @controller.set_badge_notification([@badge1, @badge2])
    
    # Mock flash to capture messages  
    flash_messages = {}
    @controller.define_singleton_method(:flash) { flash_messages }
    
    @controller.set_badge_notification_flash
    
    # Should set plural flash message
    assert_match /2個のバッジ/, flash_messages[:success]
    assert_match /おめでとうございます/, flash_messages[:success]
  end
end