require "test_helper"

class HabitTest < ActiveSupport::TestCase
  def setup
    @user = users(:one) # This assumes there's a user fixture
    @habit = Habit.new(title: "Daily exercise", description: "30 minutes of exercise daily", user: @user)
  end

  test "should be valid" do
    assert @habit.valid?
  end

  test "title should be present" do
    @habit.title = "  "
    assert_not @habit.valid?
  end

  test "title should not be too long" do
    @habit.title = "a" * 256
    assert_not @habit.valid?
  end

  test "description should not be too long" do
    @habit.description = "a" * 1001
    assert_not @habit.valid?
  end

  test "user should be present" do
    @habit.user = nil
    assert_not @habit.valid?
  end

  test "should belong to user" do
    assert_respond_to @habit, :user
  end

  test "active should default to true" do
    habit = Habit.create!(title: "Test habit", user: @user)
    assert habit.active?
  end
end