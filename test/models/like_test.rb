# frozen_string_literal: true

require "test_helper"

class LikeTest < ActiveSupport::TestCase
  test "should not allow duplicate likes" do
    user = users(:one)
    post = posts(:one)
    
    # Create first like
    like1 = Like.new(user: user, post: post)
    assert like1.valid?
    
    # Try to create duplicate like
    like2 = Like.new(user: user, post: post)
    assert_not like2.valid?
    assert_includes like2.errors[:user_id], "has already been taken"
  end

  test "should belong to user and post" do
    like = likes(:one)
    assert_respond_to like, :user
    assert_respond_to like, :post
  end
end
