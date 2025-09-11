require "test_helper"

class BadgesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get badges_index_url
    assert_response :success
  end

  test "should get show" do
    get badges_show_url
    assert_response :success
  end
end
