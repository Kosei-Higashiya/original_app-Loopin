require "test_helper"

class BadgeTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    badge = Badge.new(
      name: "First Habit",
      description: "Create your first habit",
      condition_type: "total_habits",
      condition_value: 1
    )
    assert badge.valid?
  end

  test "should require name" do
    badge = Badge.new(
      description: "Test badge",
      condition_type: "total_habits",
      condition_value: 1
    )
    assert_not badge.valid?
    assert_includes badge.errors[:name], "can't be blank"
  end

  test "should require condition_type" do
    badge = Badge.new(
      name: "Test Badge",
      condition_value: 1
    )
    assert_not badge.valid?
    assert_includes badge.errors[:condition_type], "can't be blank"
  end

  test "should require condition_value" do
    badge = Badge.new(
      name: "Test Badge",
      condition_type: "total_habits"
    )
    assert_not badge.valid?
    assert_includes badge.errors[:condition_value], "can't be blank"
  end

  test "should require unique name" do
    Badge.create!(
      name: "Unique Badge",
      condition_type: "total_habits",
      condition_value: 1
    )
    
    duplicate_badge = Badge.new(
      name: "Unique Badge",
      condition_type: "total_records",
      condition_value: 5
    )
    
    assert_not duplicate_badge.valid?
    assert_includes duplicate_badge.errors[:name], "has already been taken"
  end

  test "should return correct condition_type_name" do
    badge = Badge.new(condition_type: "consecutive_days")
    assert_equal "連続日数", badge.condition_type_name
    
    badge.condition_type = "unknown_type"
    assert_equal "unknown_type", badge.condition_type_name
  end
end