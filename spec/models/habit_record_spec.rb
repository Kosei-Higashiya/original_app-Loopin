require 'rails_helper'

RSpec.describe HabitRecord, type: :model do
  describe 'バリデーション' do
    let(:habit_record) { build(:habit_record) }

    it '有効なファクトリーを持つこと' do
      expect(habit_record).to be_valid
    end

    it 'recorded_atが必須であること' do
      habit_record.recorded_at = nil
      expect(habit_record).to_not be_valid
      expect(habit_record.errors[:recorded_at]).to include("can't be blank")
    end

    it 'noteが1000文字以下であること' do
      habit_record.note = 'a' * 1001
      expect(habit_record).to_not be_valid
      expect(habit_record.errors[:note]).to include("is too long (maximum is 1000 characters)")
    end

    it 'completedがboolean値であること' do
      habit_record.completed = nil
      expect(habit_record).to_not be_valid
      expect(habit_record.errors[:completed]).to include("is not included in the list")
    end

    it '同じユーザー・習慣・日付の記録は一意であること' do
      user = create(:user)
      habit = create(:habit, user: user)
      create(:habit_record, user: user, habit: habit, recorded_at: Date.current)

      duplicate_record = build(:habit_record, user: user, habit: habit, recorded_at: Date.current)
      expect(duplicate_record).to_not be_valid
      expect(duplicate_record.errors[:user_id]).to include("can only have one record per habit per day")
    end
  end

  describe 'アソシエーション' do
    it 'userと関連していること' do
      expect(HabitRecord.reflect_on_association(:user)).to be_present
      expect(HabitRecord.reflect_on_association(:user).macro).to eq(:belongs_to)
    end

    it 'habitと関連していること' do
      expect(HabitRecord.reflect_on_association(:habit)).to be_present
      expect(HabitRecord.reflect_on_association(:habit).macro).to eq(:belongs_to)
    end
  end

  describe 'カスタムバリデーション' do
    it '習慣がユーザーに属していること' do
      user1 = create(:user)
      user2 = create(:user)
      habit = create(:habit, user: user1)
      
      habit_record = build(:habit_record, user: user2, habit: habit)
      expect(habit_record).to_not be_valid
      expect(habit_record.errors[:habit]).to include("must belong to the same user")
    end
  end

  describe 'スコープ' do
    let(:user) { create(:user) }
    let(:habit) { create(:habit, user: user) }
    let!(:completed_record) { create(:habit_record, user: user, habit: habit, completed: true) }
    let!(:incomplete_record) { create(:habit_record, :incomplete, user: user, habit: habit, recorded_at: 1.day.ago) }
    let!(:old_record) { create(:habit_record, user: user, habit: habit, recorded_at: 2.days.ago) }

    it '.completedは完了した記録のみ返すこと' do
      expect(HabitRecord.completed).to include(completed_record)
      expect(HabitRecord.completed).to_not include(incomplete_record)
    end

    it '.incompleteは未完了の記録のみ返すこと' do
      expect(HabitRecord.incomplete).to include(incomplete_record)
      expect(HabitRecord.incomplete).to_not include(completed_record)
    end

    it '.recentは記録日時の降順で返すこと' do
      expect(HabitRecord.recent.first).to eq(completed_record)
    end

    it '.for_dateは指定した日付の記録を返すこと' do
      expect(HabitRecord.for_date(Date.current)).to include(completed_record)
      expect(HabitRecord.for_date(Date.current)).to_not include(incomplete_record)
    end
  end
end