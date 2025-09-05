require "test_helper"

class PostTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @habit = habits(:one)
    @post = Post.new(user: @user, habit: @habit, content: "Test content")
  end

  test "should be valid" do
    assert @post.valid?
  end

  test "should require content" do
    @post.content = ""
    assert_not @post.valid?
  end

  test "should belong to user" do
    @post.user = nil
    assert_not @post.valid?
  end

  test "should belong to habit" do
    @post.habit = nil
    assert_not @post.valid?
  end

  test "content should not be too long" do
    @post.content = "a" * 1001
    assert_not @post.valid?
  end
end