require 'rails_helper'

RSpec.describe Habit, type: :model do
  describe 'バリデーション' do
    let(:habit) { build(:habit) }

    it '有効なファクトリーを持つこと' do
      expect(habit).to be_valid
    end

    it 'titleが必須であること' do
      habit.title = nil
      expect(habit).to_not be_valid
      expect(habit.errors[:title]).to include("を入力してください")
    end

    it 'titleが255文字以下であること' do
      habit.title = 'a' * 256
      expect(habit).to_not be_valid
      expect(habit.errors[:title]).to include("は255文字以内で入力してください")
    end

    it 'descriptionが1000文字以下であること' do
      habit.description = 'a' * 1001
      expect(habit).to_not be_valid
      expect(habit.errors[:description]).to include("は1000文字以内で入力してください")
    end

    it 'descriptionは空でも有効であること' do
      habit.description = nil
      expect(habit).to be_valid
    end
  end

  describe 'アソシエーション' do
    it 'userと関連していること' do
      expect(Habit.reflect_on_association(:user)).to be_present
      expect(Habit.reflect_on_association(:user).macro).to eq(:belongs_to)
    end

    it 'habit_recordsと関連していること' do
      expect(Habit.reflect_on_association(:habit_records)).to be_present
      expect(Habit.reflect_on_association(:habit_records).macro).to eq(:has_many)
    end

    it 'postsと関連していること' do
      expect(Habit.reflect_on_association(:posts)).to be_present
      expect(Habit.reflect_on_association(:posts).macro).to eq(:has_many)
    end
  end

  describe 'スコープ' do
    let!(:old_habit) { create(:habit, created_at: 1.week.ago) }
    let!(:new_habit) { create(:habit, created_at: 1.day.ago) }

    it '.recentは作成日時の降順で返すこと' do
      expect(Habit.recent).to eq([new_habit, old_habit])
    end
  end

  describe 'dependent: :destroy' do
    let(:habit) { create(:habit) }

    it '習慣を削除すると関連する記録も削除されること' do
      habit_record = create(:habit_record, habit: habit)
      post = create(:post, habit: habit)

      expect {
        habit.destroy
      }.to change(HabitRecord, :count).by(-1)
       .and change(Post, :count).by(-1)
    end
  end
end
