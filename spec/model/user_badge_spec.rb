require 'rails_helper'

RSpec.describe UserBadge, type: :model do
  describe 'バリデーション' do
    let(:user) { create(:user) }
    let(:badge) { create(:badge) }
    let(:user_badge) { build(:user_badge, user: user, badge: badge) }

    it '有効なファクトリーを持つこと' do
      expect(user_badge).to be_valid
    end

    it 'earned_atが必須であること' do
      user_badge.earned_at = nil
      expect(user_badge).to_not be_valid
      expect(user_badge.errors[:earned_at]).to include('を入力してください')
    end

    it 'user_idとbadge_idの組み合わせが一意であること' do
      create(:user_badge, user: user, badge: badge)
      duplicate = build(:user_badge, user: user, badge: badge)
      expect(duplicate).to_not be_valid
      expect(duplicate.errors[:user_id]).to include('has already earned this badge')
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

    context 'user_statsパラメータを使用する場合' do
      let(:badge) { create(:badge, condition_type: 'total_records', condition_value: 5) }

      it '条件を満たす場合はバッジを付与すること' do
        user_stats = { total_records: 10, total_habits: 5, consecutive_days: 3, completion_rate: 80.0 }

        expect {
          result = UserBadge.award_badge(user, badge, user_stats: user_stats)
          expect(result).to be_a(UserBadge)
          expect(result.user).to eq(user)
          expect(result.badge).to eq(badge)
          expect(result.earned_at).to be_present
        }.to change(UserBadge, :count).by(1)
      end

      it '条件を満たさない場合はnilを返すこと' do
        user_stats = { total_records: 3, total_habits: 5, consecutive_days: 3, completion_rate: 80.0 }

        expect {
          result = UserBadge.award_badge(user, badge, user_stats: user_stats)
          expect(result).to be_nil
        }.to_not change(UserBadge, :count)
      end

      it 'すでにバッジを持っている場合はnilを返すこと' do
        create(:user_badge, user: user, badge: badge)
        user_stats = { total_records: 10, total_habits: 5, consecutive_days: 3, completion_rate: 80.0 }

        expect {
          result = UserBadge.award_badge(user, badge, user_stats: user_stats)
          expect(result).to be_nil
        }.to_not change(UserBadge, :count)
      end
    end

    context 'user_statsパラメータを使用しない場合' do
      let(:badge) { create(:badge, condition_type: 'total_records', condition_value: 2) }

      it '条件を満たす場合はバッジを付与すること' do
        create_list(:habit_record, 2, user: user, habit: habit)

        expect {
          result = UserBadge.award_badge(user, badge)
          expect(result).to be_a(UserBadge)
          expect(result.user).to eq(user)
          expect(result.badge).to eq(badge)
        }.to change(UserBadge, :count).by(1)
      end

      it '条件を満たさない場合はnilを返すこと' do
        expect {
          result = UserBadge.award_badge(user, badge)
          expect(result).to be_nil
        }.to_not change(UserBadge, :count)
      end
    end

    context '同時実行による重複の場合' do
      let(:badge) { create(:badge, condition_type: 'total_records', condition_value: 1) }

      it 'RecordNotUniqueエラーをキャッチしてnilを返すこと' do
        create_list(:habit_record, 1, user: user, habit: habit)
        
        # 最初のバッジを作成
        first_badge = UserBadge.award_badge(user, badge)
        expect(first_badge).to be_a(UserBadge)

        # データベースレベルでの重複エラーをシミュレート
        allow(UserBadge).to receive(:create!).and_raise(ActiveRecord::RecordNotUnique.new('duplicate'))

        expect {
          result = UserBadge.award_badge(user, badge)
          expect(result).to be_nil
        }.to_not change(UserBadge, :count)
      end
    end

    context '各条件タイプでの動作確認' do
      let(:user) { create(:user) }

      it 'consecutive_daysバッジが正しく付与されること' do
        badge = create(:badge, :consecutive_days_badge, condition_value: 3)
        habit = create(:habit, user: user)
        3.times do |i|
          create(:habit_record,
                 user: user,
                 habit: habit,
                 recorded_at: Date.current - i.days,
                 completed: true)
        end

        result = UserBadge.award_badge(user, badge)
        expect(result).to be_a(UserBadge)
        expect(user.badge?(badge)).to be true
      end

      it 'total_habitsバッジが正しく付与されること' do
        badge = create(:badge, :total_habits_badge, condition_value: 2)
        create_list(:habit, 2, user: user)

        result = UserBadge.award_badge(user, badge)
        expect(result).to be_a(UserBadge)
        expect(user.badge?(badge)).to be true
      end
    end
  end
end
