require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "user creation works with valid attributes" do
    user = User.new(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test User"
    )
    
    assert user.valid?, "User should be valid with proper attributes"
    assert user.save, "User should save successfully"
    assert_equal "test@example.com", user.email
    assert_equal "Test User", user.name
  end

  test "user creation works without name" do
    user = User.new(
      email: "testnoname@example.com", 
      password: "password123",
      password_confirmation: "password123"
    )
    
    assert user.valid?, "User should be valid without name"
    assert user.save, "User should save successfully without name"
    assert_equal "ゲスト", user.display_name
  end

  test "badge checking does not prevent user creation" do
    user = User.new(
      email: "badgetest@example.com",
      password: "password123", 
      password_confirmation: "password123"
    )
    
    # Should save successfully even if badge checking has issues
    assert user.save, "User should save even if badge checking fails"
    
    # Badge checking should not raise errors
    assert_nothing_raised do
      badges = user.check_and_award_badges
      assert_kind_of Array, badges
    end
  end

  test "display_name returns name or guest" do
    user_with_name = users(:one)
    user_with_name.name = "John Doe"
    assert_equal "John Doe", user_with_name.display_name

    user_without_name = users(:two)
    user_without_name.name = nil
    assert_equal "ゲスト", user_without_name.display_name
  end
end
