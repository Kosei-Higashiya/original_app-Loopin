require "test_helper"

class BadgeCheckerTest < ActiveSupport::TestCase
  include BadgeChecker

  def setup
    @user = User.create!(
      email: "test@example.com", 
      password: "password123",
      password_confirmation: "password123",
      name: "Test User"
    )
    
    @habit = @user.habits.create!(
      name: "Test Habit",
      description: "Test Description"
    )
    
    # Create a consecutive days badge for testing
    @consecutive_badge = Badge.create!(
      name: "3日連続",
      description: "3日間連続で記録",
      condition_type: "consecutive_days",
      condition_value: 3,
      active: true,
      icon: "🔥"
    )
  end

  test "calculate_max_consecutive_days with optimized logic" do
    # Create 3 consecutive days of records
    3.times do |i|
      @user.habit_records.create!(
        habit: @habit,
        recorded_at: Date.current - i.days,
        completed: true
      )
    end
    
    result = calculate_max_consecutive_days(@user)
    assert_equal 3, result, "Expected 3 consecutive days from optimized calculation"
  end

  test "badge is awarded when consecutive days condition is met" do
    # Create 3 consecutive days of records
    3.times do |i|
      @user.habit_records.create!(
        habit: @habit,
        recorded_at: Date.current - i.days,
        completed: true
      )
    end
    
    # Perform badge check
    results = perform_badge_check_for_user(@user)
    
    assert_equal 1, results[:newly_earned].count, "Expected 1 new badge"
    assert_equal @consecutive_badge.id, results[:newly_earned].first.id
    assert results[:errors].empty?, "Expected no errors"
  end

  test "badge is not awarded when condition is not met" do
    # Create only 2 consecutive days (less than required 3)
    2.times do |i|
      @user.habit_records.create!(
        habit: @habit,
        recorded_at: Date.current - i.days,
        completed: true
      )
    end
    
    results = perform_badge_check_for_user(@user)
    
    assert_equal 0, results[:newly_earned].count, "Expected no new badges"
    assert results[:errors].empty?, "Expected no errors"
  end

  test "badge is not awarded twice for same condition" do
    # Create 4 consecutive days
    4.times do |i|
      @user.habit_records.create!(
        habit: @habit,
        recorded_at: Date.current - i.days,
        completed: true
      )
    end
    
    # First badge check
    results1 = perform_badge_check_for_user(@user)
    assert_equal 1, results1[:newly_earned].count
    
    # Second badge check should not award the same badge again
    results2 = perform_badge_check_for_user(@user)
    assert_equal 0, results2[:newly_earned].count, "Badge should not be awarded twice"
  end

  test "user stats calculation includes consecutive days" do
    3.times do |i|
      @user.habit_records.create!(
        habit: @habit,
        recorded_at: Date.current - i.days,
        completed: true
      )
    end
    
    stats = calculate_user_stats(@user)
    
    assert_equal 3, stats[:consecutive_days]
    assert_equal 1, stats[:total_habits]
    assert_equal 3, stats[:total_records]
    assert stats[:completion_rate] > 0
  end
end