require 'rails_helper'

RSpec.describe UserBadge, type: :model do
  describe 'バリデーション' do
    let(:user) { create(:user) }
    let(:badge) { create(:badge) }
    let(:user_badge) { build(:user_badge, user: user, badge: badge) }

    it '有効なインスタンスを持つこと' do
      expect(user_badge).to be_valid
    end

    it 'earned_atが必須であること' do
      user_badge.earned_at = nil
      expect(user_badge).to_not be_valid
      expect(user_badge.errors[:earned_at]).to include('を入力してください')
    end

    it 'user_idとbadge_idの組み合わせが一意であること' do
      create(:user_badge, user: user, badge: badge)
      duplicate_badge = build(:user_badge, user: user, badge: badge)
      expect(duplicate_badge).to_not be_valid
      expect(duplicate_badge.errors[:user_id]).to include('has already earned this badge')
    end
  end

  describe 'アソシエーション' do
    it 'userと関連していること' do
      expect(UserBadge.reflect_on_association(:user)).to be_present
      expect(UserBadge.reflect_on_association(:user).macro).to eq(:belongs_to)
    end

    it 'badgeと関連していること' do
      expect(UserBadge.reflect_on_association(:badge)).to be_present
      expect(UserBadge.reflect_on_association(:badge).macro).to eq(:belongs_to)
    end
  end

  describe '.award_badge' do
    let(:user) { create(:user) }
    let(:habit) { create(:habit, user: user) }

    context 'user_statsパラメータなしの場合' do
      let(:badge) { create(:badge, condition_type: 'total_records', condition_value: 1) }

      it 'バッジの条件を満たす場合はUserBadgeを作成すること' do
        create(:habit_record, user: user, habit: habit)
        
        expect {
          result = UserBadge.award_badge(user, badge)
          expect(result).to be_a(UserBadge)
          expect(result.user).to eq(user)
          expect(result.badge).to eq(badge)
          expect(result.earned_at).to be_present
        }.to change(UserBadge, :count).by(1)
      end

      it 'バッジの条件を満たさない場合はnilを返すこと' do
        expect {
          result = UserBadge.award_badge(user, badge)
          expect(result).to be_nil
        }.to_not change(UserBadge, :count)
      end

      it 'すでにバッジを持っている場合はnilを返すこと' do
        create(:habit_record, user: user, habit: habit)
        create(:user_badge, user: user, badge: badge)
        
        expect {
          result = UserBadge.award_badge(user, badge)
          expect(result).to be_nil
        }.to_not change(UserBadge, :count)
      end
    end

    context 'user_statsパラメータありの場合' do
      let(:badge) { create(:badge, condition_type: 'consecutive_days', condition_value: 5) }

      it 'user_statsを使って条件を判定すること' do
        user_stats = {
          consecutive_days: 7,
          total_habits: 2,
          total_records: 10,
          completion_rate: 80.0
        }
        
        expect {
          result = UserBadge.award_badge(user, badge, user_stats: user_stats)
          expect(result).to be_a(UserBadge)
          expect(result.user).to eq(user)
          expect(result.badge).to eq(badge)
        }.to change(UserBadge, :count).by(1)
      end

      it 'user_statsで条件を満たさない場合はnilを返すこと' do
        user_stats = {
          consecutive_days: 3,
          total_habits: 2,
          total_records: 10,
          completion_rate: 80.0
        }
        
        expect {
          result = UserBadge.award_badge(user, badge, user_stats: user_stats)
          expect(result).to be_nil
        }.to_not change(UserBadge, :count)
      end
    end

    context '同時実行時の重複防止' do
      let(:badge) { create(:badge, condition_type: 'total_records', condition_value: 1) }

      it 'RecordNotUniqueが発生した場合はnilを返すこと' do
        create(:habit_record, user: user, habit: habit)
        
        # 最初のバッジ作成
        first_result = UserBadge.award_badge(user, badge)
        expect(first_result).to be_a(UserBadge)
        
        # ActiveRecord::RecordNotUniqueをシミュレート
        allow(UserBadge).to receive(:create!).and_raise(ActiveRecord::RecordNotUnique)
        
        user_stats = {
          consecutive_days: 1,
          total_habits: 1,
          total_records: 1,
          completion_rate: 100.0
        }
        
        expect {
          result = UserBadge.award_badge(user, badge, user_stats: user_stats)
          expect(result).to be_nil
        }.to_not change(UserBadge, :count)
      end
    end
  end
end
