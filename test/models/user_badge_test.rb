require "test_helper"

class UserBadgeTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @badge = badges(:first_habit)
  end

  test "should be valid with valid attributes" do
    user_badge = UserBadge.new(
      user: @user,
      badge: @badge,
      earned_at: Time.current
    )
    assert user_badge.valid?
  end

  test "should require user" do
    user_badge = UserBadge.new(
      badge: @badge,
      earned_at: Time.current
    )
    assert_not user_badge.valid?
    assert_includes user_badge.errors[:user], "must exist"
  end

  test "should require badge" do
    user_badge = UserBadge.new(
      user: @user,
      earned_at: Time.current
    )
    assert_not user_badge.valid?
    assert_includes user_badge.errors[:badge], "must exist"
  end

  test "should require earned_at" do
    user_badge = UserBadge.new(
      user: @user,
      badge: @badge
    )
    assert_not user_badge.valid?
    assert_includes user_badge.errors[:earned_at], "can't be blank"
  end

  test "should not allow duplicate user-badge combination" do
    UserBadge.create!(
      user: @user,
      badge: @badge,
      earned_at: Time.current
    )
    
    duplicate_user_badge = UserBadge.new(
      user: @user,
      badge: @badge,
      earned_at: Time.current
    )
    
    assert_not duplicate_user_badge.valid?
    assert_includes duplicate_user_badge.errors[:user_id], "has already earned this badge"
  end
end