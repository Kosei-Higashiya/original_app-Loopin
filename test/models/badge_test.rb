require "test_helper"

class BadgeTest < ActiveSupport::TestCase
  fixtures :users, :habits, :habit_records, :badges, :user_badges

  def setup
    @user = users(:user_one)
    @habit = habits(:habit_one) 
    @consecutive_badge = badges(:consecutive_days_badge)
    @total_habits_badge = badges(:total_habits_badge)
    @total_records_badge = badges(:total_records_badge)
    @completion_rate_badge = badges(:completion_rate_badge)
  end

  test "consecutive_days badge condition with consecutive records" do
    # Create consecutive records for 3 days
    @user.habit_records.create!(
      habit: @habit,
      recorded_at: Date.current - 2,
      completed: true
    )
    @user.habit_records.create!(
      habit: @habit,
      recorded_at: Date.current - 1,
      completed: true
    )
    @user.habit_records.create!(
      habit: @habit,
      recorded_at: Date.current,
      completed: true
    )

    badge = Badge.create!(
      name: "3日連続テスト",
      description: "3日間連続で記録",
      condition_type: "consecutive_days",
      condition_value: 3,
      icon: "🔥"
    )

    assert badge.earned_by?(@user), "User should earn consecutive days badge"
  end

  test "consecutive_days badge condition with non-consecutive records" do
    # Create non-consecutive records with a gap
    @user.habit_records.create!(
      habit: @habit,
      recorded_at: Date.current - 3,
      completed: true
    )
    # Skip day -2
    @user.habit_records.create!(
      habit: @habit,
      recorded_at: Date.current - 1,
      completed: true
    )
    @user.habit_records.create!(
      habit: @habit,
      recorded_at: Date.current,
      completed: true
    )

    badge = Badge.create!(
      name: "3日連続テスト",
      description: "3日間連続で記録",
      condition_type: "consecutive_days",
      condition_value: 3,
      icon: "🔥"
    )

    assert_not badge.earned_by?(@user), "User should not earn badge with non-consecutive records"
  end

  test "consecutive_days calculation with duplicate dates" do
    # Create multiple records on the same date (should count as one day)
    @user.habit_records.create!(
      habit: @habit,
      recorded_at: Date.current - 1,
      completed: true
    )
    @user.habit_records.create!(
      habit: @habit,
      recorded_at: Date.current - 1,
      completed: true
    )
    @user.habit_records.create!(
      habit: @habit,
      recorded_at: Date.current,
      completed: true
    )

    badge = Badge.create!(
      name: "3日連続テスト",
      description: "3日間連続で記録",
      condition_type: "consecutive_days",
      condition_value: 3,
      icon: "🔥"
    )

    assert_not badge.earned_by?(@user), "Multiple records on same date should count as one day"
    assert_equal 2, @user.max_consecutive_days, "Should only count unique consecutive dates"
  end

  test "total_habits badge condition" do
    # Create additional habits
    @user.habits.create!(title: "Habit 2", description: "Second habit")
    @user.habits.create!(title: "Habit 3", description: "Third habit")

    badge = Badge.create!(
      name: "習慣コレクター",
      description: "3つの習慣を作成",
      condition_type: "total_habits",
      condition_value: 3,
      icon: "📝"
    )

    assert badge.earned_by?(@user), "User should earn total habits badge"
  end

  test "total_records badge condition" do
    # Create multiple habit records
    10.times do |i|
      @user.habit_records.create!(
        habit: @habit,
        recorded_at: Date.current - i,
        completed: true
      )
    end

    badge = Badge.create!(
      name: "記録王",
      description: "10回記録",
      condition_type: "total_records",
      condition_value: 10,
      icon: "👑"
    )

    assert badge.earned_by?(@user), "User should earn total records badge"
  end

  test "completion_rate badge condition" do
    # Create 10 records: 9 completed, 1 incomplete (90% completion rate)
    9.times do |i|
      @user.habit_records.create!(
        habit: @habit,
        recorded_at: Date.current - i,
        completed: true
      )
    end
    @user.habit_records.create!(
      habit: @habit,
      recorded_at: Date.current - 9,
      completed: false
    )

    badge = Badge.create!(
      name: "完璧主義者",
      description: "完了率90%以上",
      condition_type: "completion_rate",
      condition_value: 90,
      icon: "✨"
    )

    assert badge.earned_by?(@user), "User should earn completion rate badge with 90% completion"
  end

  test "user max_consecutive_days calculation" do
    # Test the fixed consecutive days calculation
    @user.habit_records.create!(
      habit: @habit,
      recorded_at: Date.current - 4,
      completed: true
    )
    @user.habit_records.create!(
      habit: @habit,
      recorded_at: Date.current - 3,
      completed: true
    )
    @user.habit_records.create!(
      habit: @habit,
      recorded_at: Date.current - 2,
      completed: true
    )
    # Skip day -1
    @user.habit_records.create!(
      habit: @habit,
      recorded_at: Date.current,
      completed: true
    )

    # Should find the longest streak (3 days)
    assert_equal 3, @user.max_consecutive_days, "Should calculate correct consecutive days"
  end
end
