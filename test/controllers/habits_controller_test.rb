require "test_helper"

class HabitsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get habits_index_url
    assert_response :success
  end

  test "should get show" do
    get habits_show_url
    assert_response :success
  end

  test "should get new" do
    get habits_new_url
    assert_response :success
  end

  test "should get create" do
    get habits_create_url
    assert_response :success
  end

  test "should get edit" do
    get habits_edit_url
    assert_response :success
  end

  test "should get update" do
    get habits_update_url
    assert_response :success
  end

  test "should get destroy" do
    get habits_destroy_url
    assert_response :success
  end

  test "should get calendar" do
    get calendar_habits_url
    assert_response :success
  end
end
