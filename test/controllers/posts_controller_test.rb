require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @habit = habits(:one)
    sign_in @user
  end

  test "should get index" do
    get posts_url
    assert_response :success
  end

  test "should get new" do
    get new_post_url
    assert_response :success
  end

  test "should create post" do
    assert_difference("Post.count") do
      post posts_url, params: { post: { habit_id: @habit.id, content: "Test content" } }
    end

    assert_redirected_to posts_url
  end

  test "should show post" do
    post = Post.create!(user: @user, habit: @habit, content: "Test content")
    get post_url(post)
    assert_response :success
  end

  test "should destroy own post" do
    post = Post.create!(user: @user, habit: @habit, content: "Test content")
    assert_difference("Post.count", -1) do
      delete post_url(post)
    end

    assert_redirected_to posts_url
  end
end