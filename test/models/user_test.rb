require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "display_name returns name when name is present" do
    user = User.new(name: "田中太郎", email: "tanaka@example.com")
    assert_equal "田中太郎", user.display_name
  end

  test "display_name returns ゲスト when name is blank" do
    user = User.new(name: "", email: "user@example.com")
    assert_equal "ゲスト", user.display_name
  end

  test "display_name returns ゲスト when name is nil" do
    user = User.new(name: nil, email: "user@example.com")
    assert_equal "ゲスト", user.display_name
  end

  test "display_name returns ゲスト when name is whitespace only" do
    user = User.new(name: "   ", email: "user@example.com")
    assert_equal "ゲスト", user.display_name
  end
end
