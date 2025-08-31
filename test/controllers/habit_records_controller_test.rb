require "test_helper"

class HabitRecordsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @other_user = users(:two)
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

  test "should get show for public record" do
    sign_in @user
    get habit_record_path(@habit_record)
    assert_response :success
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
    assert_redirected_to HabitRecord.last
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

  test "should get edit for own record" do
    sign_in @user
    get edit_habit_record_path(@habit_record)
    assert_response :success
  end

  test "should update own habit_record" do
    sign_in @user
    patch habit_record_path(@habit_record), params: {
      habit_record: { title: "Updated Title" }
    }
    assert_redirected_to @habit_record
    @habit_record.reload
    assert_equal "Updated Title", @habit_record.title
  end

  test "should destroy own habit_record" do
    sign_in @user
    assert_difference("HabitRecord.count", -1) do
      delete habit_record_path(@habit_record)
    end
    assert_redirected_to habit_records_path
  end

  test "should not edit other user's record" do
    sign_in @other_user
    get edit_habit_record_path(@habit_record)
    assert_redirected_to habit_records_path
  end

  test "should not update other user's record" do
    sign_in @other_user
    patch habit_record_path(@habit_record), params: {
      habit_record: { title: "Hacked Title" }
    }
    assert_redirected_to habit_records_path
    @habit_record.reload
    assert_not_equal "Hacked Title", @habit_record.title
  end

  test "should not destroy other user's record" do
    sign_in @other_user
    assert_no_difference("HabitRecord.count") do
      delete habit_record_path(@habit_record)
    end
    assert_redirected_to habit_records_path
  end
end