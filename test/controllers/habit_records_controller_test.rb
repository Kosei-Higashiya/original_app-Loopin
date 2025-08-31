require "test_helper"

class HabitRecordsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @habit_record = habit_records(:one)
  end

  test "should redirect to login when not authenticated" do
    get habit_records_path
    assert_redirected_to new_user_session_path
  end

  test "should get index when authenticated" do
    sign_in @user
    get habit_records_path
    assert_response :success
    assert_select "h1", "みんなの習慣"
  end

  test "should get new when authenticated" do
    sign_in @user
    get new_habit_record_path
    assert_response :success
    assert_select "h1", "新しい習慣記録を投稿"
  end

  test "should create habit_record when authenticated" do
    sign_in @user
    assert_difference("HabitRecord.count", 1) do
      post habit_records_path, params: {
        habit_record: {
          title: "New Habit Record",
          content: "Test content",
          is_public: true,
          recorded_at: Date.current
        }
      }
    end
    assert_redirected_to habit_records_path
  end

  test "should not create habit_record with invalid data" do
    sign_in @user
    assert_no_difference("HabitRecord.count") do
      post habit_records_path, params: {
        habit_record: {
          title: "", # Invalid - title is required
          content: "Test content"
        }
      }
    end
    assert_response :unprocessable_entity
  end
end