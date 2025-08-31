require "test_helper"

class HabitsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @habit = habits(:one) # This assumes there's a habit fixture
    sign_in @user
  end

  test "should get index" do
    get habits_url
    assert_response :success
  end

  test "should get new" do
    get new_habit_url
    assert_response :success
  end

  test "should create habit" do
    assert_difference("Habit.count") do
      post habits_url, params: { habit: { title: "New habit", description: "Test description", active: true } }
    end

    assert_redirected_to habit_url(Habit.last)
  end

  test "should show habit" do
    get habit_url(@habit)
    assert_response :success
  end

  test "should get edit" do
    get edit_habit_url(@habit)
    assert_response :success
  end

  test "should update habit" do
    patch habit_url(@habit), params: { habit: { title: "Updated title", description: "Updated description" } }
    assert_redirected_to habit_url(@habit)
  end

  test "should destroy habit" do
    assert_difference("Habit.count", -1) do
      delete habit_url(@habit)
    end

    assert_redirected_to habits_url
  end

  test "should require authentication" do
    sign_out @user
    get habits_url
    assert_redirected_to new_user_session_path
  end
end