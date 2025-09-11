require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
  end

  test "display_name returns name when present" do
    @user.name = "Test User"
    assert_equal "Test User", @user.display_name
  end

  test "display_name returns ゲスト when name is blank" do
    @user.name = nil
    assert_equal "ゲスト", @user.display_name
    
    @user.name = ""
    assert_equal "ゲスト", @user.display_name
  end

  test "has_badge? returns true when user has badge" do
    badge = badges(:first_habit)
    UserBadge.create!(user: @user, badge: badge, earned_at: Time.current)
    assert @user.has_badge?(badge)
  end

  test "has_badge? returns false when user does not have badge" do
    badge = badges(:habit_master)
    assert_not @user.has_badge?(badge)
  end

  test "earned_badges returns badges in earned order" do
    badge1 = badges(:first_habit)
    badge2 = badges(:habit_master)
    
    UserBadge.create!(user: @user, badge: badge1, earned_at: 2.days.ago)
    UserBadge.create!(user: @user, badge: badge2, earned_at: 1.day.ago)
    
    earned_badges = @user.earned_badges
    assert_equal badge2, earned_badges.first
    assert_equal badge1, earned_badges.second
  end
end
