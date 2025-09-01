require "test_helper"

class HabitRecordTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @habit = habits(:one)
    @habit_record = HabitRecord.new(
      user: @user,
      habit: @habit,
      recorded_at: Date.current,
      completed: true
    )
  end

  test "should be valid with valid attributes" do
    assert @habit_record.valid?
  end

  test "should require recorded_at" do
    @habit_record.recorded_at = nil
    assert_not @habit_record.valid?
    assert_includes @habit_record.errors[:recorded_at], "can't be blank"
  end

  test "should require user" do
    @habit_record.user = nil
    assert_not @habit_record.valid?
    assert_includes @habit_record.errors[:user], "must exist"
  end

  test "should require habit" do
    @habit_record.habit = nil
    assert_not @habit_record.valid?
    assert_includes @habit_record.errors[:habit], "must exist"
  end

  test "should validate notes length" do
    @habit_record.notes = "a" * 1001
    assert_not @habit_record.valid?
    assert_includes @habit_record.errors[:notes], "is too long (maximum is 1000 characters)"
  end

  test "should allow valid notes length" do
    @habit_record.notes = "a" * 1000
    assert @habit_record.valid?
  end

  test "should validate completed is boolean" do
    @habit_record.completed = nil
    assert_not @habit_record.valid?
    assert_includes @habit_record.errors[:completed], "is not included in the list"
  end

  test "should enforce uniqueness per user habit and date" do
    @habit_record.save!
    
    duplicate_record = HabitRecord.new(
      user: @user,
      habit: @habit,
      recorded_at: @habit_record.recorded_at,
      completed: false
    )
    
    assert_not duplicate_record.valid?
    assert_includes duplicate_record.errors[:user_id], "can only have one record per habit per day"
  end

  test "should allow same date for different habits" do
    @habit_record.save!
    
    other_habit = habits(:two)
    other_record = HabitRecord.new(
      user: @user,
      habit: other_habit,
      recorded_at: @habit_record.recorded_at,
      completed: true
    )
    
    assert other_record.valid?
  end

  test "should allow same date for different users" do
    @habit_record.save!
    
    other_user = users(:two)
    other_habit = Habit.create!(title: "Other habit", user: other_user)
    other_record = HabitRecord.new(
      user: other_user,
      habit: other_habit,
      recorded_at: @habit_record.recorded_at,
      completed: true
    )
    
    assert other_record.valid?
  end

  test "should validate habit belongs to user" do
    other_user = users(:two)
    other_habit = Habit.create!(title: "Other habit", user: other_user)
    
    invalid_record = HabitRecord.new(
      user: @user,
      habit: other_habit,
      recorded_at: Date.current,
      completed: true
    )
    
    assert_not invalid_record.valid?
    assert_includes invalid_record.errors[:habit], "must belong to the same user"
  end

  test "completed scope should return only completed records" do
    completed_record = HabitRecord.create!(
      user: @user,
      habit: @habit,
      recorded_at: Date.current,
      completed: true
    )
    
    incomplete_record = HabitRecord.create!(
      user: @user,
      habit: @habit,
      recorded_at: Date.current - 1.day,
      completed: false
    )
    
    completed_records = HabitRecord.completed
    assert_includes completed_records, completed_record
    assert_not_includes completed_records, incomplete_record
  end

  test "incomplete scope should return only incomplete records" do
    completed_record = HabitRecord.create!(
      user: @user,
      habit: @habit,
      recorded_at: Date.current,
      completed: true
    )
    
    incomplete_record = HabitRecord.create!(
      user: @user,
      habit: @habit,
      recorded_at: Date.current - 1.day,
      completed: false
    )
    
    incomplete_records = HabitRecord.incomplete
    assert_includes incomplete_records, incomplete_record
    assert_not_includes incomplete_records, completed_record
  end

  test "for_date scope should return records for specific date" do
    today_record = HabitRecord.create!(
      user: @user,
      habit: @habit,
      recorded_at: Date.current,
      completed: true
    )
    
    yesterday_record = HabitRecord.create!(
      user: @user,
      habit: @habit,
      recorded_at: Date.current - 1.day,
      completed: true
    )
    
    today_records = HabitRecord.for_date(Date.current)
    assert_includes today_records, today_record
    assert_not_includes today_records, yesterday_record
  end
end