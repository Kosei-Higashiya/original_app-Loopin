# frozen_string_literal: true

require 'test_helper'

class PostTest < ActiveSupport::TestCase
  test "should respond to liked_by method" do
    post = posts(:one)
    user = users(:one)
    
    assert_respond_to post, :liked_by?
    assert_not post.liked_by?(user)
  end
  
  test "liked_by should return false for nil user" do
    post = posts(:one)
    assert_not post.liked_by?(nil)
  end

  test "should have many likes" do
    post = posts(:one)
    assert_respond_to post, :likes
    assert_respond_to post, :liked_by_users
  end
end
