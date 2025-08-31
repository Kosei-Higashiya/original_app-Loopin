require "test_helper"

class HabitRecordTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @habit_record = HabitRecord.new(
      title: "Morning Run",
      content: "Ran 5km this morning",
      user: @user,
      recorded_at: Date.current
    )
  end

  test "should be valid" do
    assert @habit_record.valid?
  end

  test "title should be present" do
    @habit_record.title = ""
    assert_not @habit_record.valid?
  end

  test "title should not be too long" do
    @habit_record.title = "a" * 256
    assert_not @habit_record.valid?
  end

  test "content should not be too long" do
    @habit_record.content = "a" * 1001
    assert_not @habit_record.valid?
  end

  test "user should be present" do
    @habit_record.user = nil
    assert_not @habit_record.valid?
  end

  test "should be public by default" do
    assert @habit_record.is_public
  end

  test "should have recorded_at date" do
    habit_record = @user.habit_records.create!(title: "Test", content: "Test content")
    assert_not_nil habit_record.recorded_at
  end

  test "public_records scope should return only public records" do
    public_record = @user.habit_records.create!(title: "Public", is_public: true)
    private_record = @user.habit_records.create!(title: "Private", is_public: false)
    
    public_records = HabitRecord.public_records
    assert_includes public_records, public_record
    assert_not_includes public_records, private_record
  end

  test "recent scope should order by created_at desc" do
    older_record = @user.habit_records.create!(title: "Older", created_at: 2.days.ago)
    newer_record = @user.habit_records.create!(title: "Newer", created_at: 1.day.ago)
    
    recent_records = HabitRecord.recent
    assert_equal newer_record, recent_records.first
  end
end