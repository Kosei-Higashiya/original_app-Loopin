require "test_helper"

class UserConsecutiveDaysTest < ActiveSupport::TestCase
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
  end

  test "consecutive days calculation with no records" do
    assert_equal 0, @user.max_consecutive_days
  end

  test "consecutive days calculation with single day" do
    @user.habit_records.create!(
      habit: @habit,
      recorded_at: Date.current,
      completed: true
    )
    
    assert_equal 1, @user.max_consecutive_days
  end

  test "consecutive days calculation with 3 consecutive days" do
    # Create records for 3 consecutive days
    3.times do |i|
      @user.habit_records.create!(
        habit: @habit,
        recorded_at: Date.current - i.days,
        completed: true
      )
    end
    
    result = @user.max_consecutive_days
    assert_equal 3, result, "Expected 3 consecutive days, got #{result}"
  end

  test "consecutive days calculation with gap in between" do
    # Day 1
    @user.habit_records.create!(
      habit: @habit,
      recorded_at: Date.current,
      completed: true
    )
    
    # Day 3 (gap on day 2)
    @user.habit_records.create!(
      habit: @habit,
      recorded_at: Date.current - 2.days,
      completed: true
    )
    
    # Day 4
    @user.habit_records.create!(
      habit: @habit,
      recorded_at: Date.current - 3.days,
      completed: true
    )
    
    result = @user.max_consecutive_days
    assert_equal 2, result, "Expected max 2 consecutive days due to gap, got #{result}"
  end

  test "consecutive days calculation with multiple habits same day" do
    habit2 = @user.habits.create!(name: "Habit 2", description: "Second habit")
    
    # Same day, different habits
    @user.habit_records.create!(
      habit: @habit,
      recorded_at: Date.current,
      completed: true
    )
    
    @user.habit_records.create!(
      habit: habit2,
      recorded_at: Date.current,
      completed: true
    )
    
    result = @user.max_consecutive_days
    assert_equal 1, result, "Multiple habits on same day should count as 1 consecutive day, got #{result}"
  end

  test "consecutive days calculation ignores incomplete records" do
    # Completed record
    @user.habit_records.create!(
      habit: @habit,
      recorded_at: Date.current,
      completed: true
    )
    
    # Incomplete record (should be ignored)
    @user.habit_records.create!(
      habit: @habit,
      recorded_at: Date.current - 1.day,
      completed: false
    )
    
    # Another completed record
    @user.habit_records.create!(
      habit: @habit,
      recorded_at: Date.current - 2.days,
      completed: true
    )
    
    result = @user.max_consecutive_days
    assert_equal 2, result, "Should ignore incomplete records and count 2 consecutive days, got #{result}"
  end
end