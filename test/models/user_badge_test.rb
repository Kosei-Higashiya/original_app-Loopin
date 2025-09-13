require "test_helper"

class UserBadgeTest < ActiveSupport::TestCase
  fixtures :users, :habits, :badges, :user_badges

  def setup
    @user = users(:user_one)
    @habit = habits(:habit_one)
    @badge = badges(:consecutive_days_badge)
  end

  test "award_badge creates new user badge when conditions met" do
    # Setup consecutive records to meet badge condition
    3.times do |i|
      @user.habit_records.create!(
        habit: @habit,
        recorded_at: Date.current - (2 - i),
        completed: true
      )
    end

    assert_difference('@user.user_badges.count') do
      user_badge = UserBadge.award_badge(@user, @badge)
      assert_not_nil user_badge
      assert_equal @user, user_badge.user
      assert_equal @badge, user_badge.badge
      assert_not_nil user_badge.earned_at
    end
  end

  test "award_badge returns nil when user already has badge" do
    # First award
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

    UserBadge.award_badge(@user, @badge)

    # Try to award again - should return nil
    assert_no_difference('@user.user_badges.count') do
      result = UserBadge.award_badge(@user, @badge)
      assert_nil result
    end
  end

  test "award_badge returns nil when conditions not met" do
    # Create only 2 consecutive records (badge requires 3)
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

    assert_no_difference('@user.user_badges.count') do
      result = UserBadge.award_badge(@user, @badge)
      assert_nil result
    end
  end

  test "user has_badge? method" do
    assert_not @user.has_badge?(@badge)
    
    # Award badge
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
    
    UserBadge.award_badge(@user, @badge)
    
    assert @user.has_badge?(@badge)
  end
end
