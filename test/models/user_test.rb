require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "display_name returns nickname when present" do
    user = User.new(email: "test@example.com", nickname: "TestUser")
    assert_equal "TestUser", user.display_name
  end

  test "display_name returns email prefix when nickname is nil" do
    user = User.new(email: "alice@example.com", nickname: nil)
    assert_equal "alice", user.display_name
  end

  test "display_name returns email prefix when nickname is empty" do
    user = User.new(email: "bob@example.com", nickname: "")
    assert_equal "bob", user.display_name
  end

  test "display_name returns email prefix when nickname is whitespace only" do
    user = User.new(email: "charlie@example.com", nickname: "   ")
    assert_equal "charlie", user.display_name
  end
end
