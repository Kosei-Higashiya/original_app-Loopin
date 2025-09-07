require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "display_name returns name when present" do
    user = User.new(email: "test@example.com", name: "TestUser")
    assert_equal "TestUser", user.display_name
  end

  test "display_name returns email prefix when name is nil" do
    user = User.new(email: "alice@example.com", name: nil)
    assert_equal "alice", user.display_name
  end

  test "display_name returns email prefix when name is empty" do
    user = User.new(email: "bob@example.com", name: "")
    assert_equal "bob", user.display_name
  end

  test "display_name returns email prefix when name is whitespace only" do
    user = User.new(email: "charlie@example.com", name: "   ")
    assert_equal "charlie", user.display_name
  end
end
