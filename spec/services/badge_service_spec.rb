require 'rails_helper'

RSpec.describe BadgeService, type: :service do
  describe '.check_and_award_badges_for_user' do
    let(:user) { create(:user) }
    let(:habit) { create(:habit, user: user) }

    context 'バッジが獲得できる場合' do
      let!(:badge) { create(:badge, condition_type: 'total_records', condition_value: 2, active: true) }

      before do
        create_list(:habit_record, 2, user: user, habit: habit, completed: true)
      end

      it '新しいバッジを付与すること' do
        results = BadgeService.check_and_award_badges_for_user(user)

        expect(results[:newly_earned].count).to eq(1)
        expect(results[:newly_earned].first).to eq(badge)
        expect(user.badges).to include(badge)
      end

      it '統計情報を返すこと' do
        results = BadgeService.check_and_award_badges_for_user(user)

        expect(results[:stats]).to be_present
        expect(results[:stats][:total_habits]).to eq(user.habits.count)
        expect(results[:stats][:total_records]).to eq(user.habit_records.count)
      end

      it 'エラーがないこと' do
        results = BadgeService.check_and_award_badges_for_user(user)

        expect(results[:errors]).to be_empty
      end
    end

    context '既に獲得済みのバッジがある場合' do
      let!(:badge) { create(:badge, condition_type: 'total_records', condition_value: 1, active: true) }

      before do
        create(:habit_record, user: user, habit: habit, completed: true)
        UserBadge.award_badge(user, badge)
      end

      it '重複してバッジを付与しないこと' do
        results = BadgeService.check_and_award_badges_for_user(user)

        expect(results[:newly_earned]).to be_empty
        expect(user.user_badges.where(badge: badge).count).to eq(1)
      end
    end

    context '複数のバッジが獲得できる場合' do
      let!(:badge1) { create(:badge, condition_type: 'total_records', condition_value: 2, active: true) }
      let!(:badge2) { create(:badge, condition_type: 'total_habits', condition_value: 1, active: true) }

      before do
        create_list(:habit_record, 2, user: user, habit: habit, completed: true)
      end

      it '複数のバッジを付与すること' do
        results = BadgeService.check_and_award_badges_for_user(user)

        expect(results[:newly_earned].count).to eq(2)
        expect(results[:newly_earned]).to include(badge1, badge2)
      end
    end

    context 'バッジが非アクティブの場合' do
      let!(:badge) { create(:badge, :inactive, condition_type: 'total_records', condition_value: 1) }

      before do
        create(:habit_record, user: user, habit: habit, completed: true)
      end

      it 'バッジを付与しないこと' do
        results = BadgeService.check_and_award_badges_for_user(user)

        expect(results[:newly_earned]).to be_empty
        expect(user.badges).not_to include(badge)
      end
    end

    context '連続日数バッジの場合' do
      let!(:badge) { create(:badge, :consecutive_days_badge, condition_value: 3, active: true) }

      before do
        3.times do |i|
          create(:habit_record,
                 user: user,
                 habit: habit,
                 recorded_at: Date.current - i.days,
                 completed: true)
        end
      end

      it '連続日数を正しく計算してバッジを付与すること' do
        results = BadgeService.check_and_award_badges_for_user(user)

        expect(results[:newly_earned]).to include(badge)
        expect(results[:stats][:consecutive_days]).to eq(3)
      end
    end

    context '完了率バッジの場合' do
      let!(:badge) { create(:badge, condition_type: 'completion_rate', condition_value: 50.0, active: true) }

      before do
        # 過去31日間のうち16日記録して50%以上達成 (16/31 = 51.6%)
        16.times do |i|
          create(:habit_record,
                 user: user,
                 habit: habit,
                 recorded_at: Date.current - i.days,
                 completed: true)
        end
      end

      it '完了率を正しく計算してバッジを付与すること' do
        results = BadgeService.check_and_award_badges_for_user(user)

        expect(results[:newly_earned]).to include(badge)
        expect(results[:stats][:completion_rate]).to be >= 50.0
      end
    end
  end

  describe '.calculate_user_stats' do
    let(:user) { create(:user) }
    let(:habit) { create(:habit, user: user) }

    before do
      create_list(:habit_record, 5, user: user, habit: habit, completed: true)
    end

    it 'ユーザーの統計情報を計算すること' do
      stats = BadgeService.send(:calculate_user_stats, user)

      expect(stats[:total_habits]).to eq(user.habits.count)
      expect(stats[:total_records]).to eq(user.habit_records.count)
      expect(stats[:completed_records]).to be_present
      expect(stats[:consecutive_days]).to be_present
      expect(stats[:completion_rate]).to be_present
    end
  end

  describe '.calculate_max_consecutive_days' do
    let(:user) { create(:user) }
    let(:habit) { create(:habit, user: user) }

    context '連続した記録がある場合' do
      before do
        3.times do |i|
          create(:habit_record,
                 user: user,
                 habit: habit,
                 recorded_at: Date.current - i.days,
                 completed: true)
        end
      end

      it '正しい連続日数を計算すること' do
        result = BadgeService.send(:calculate_max_consecutive_days, user)
        expect(result).to eq(3)
      end
    end

    context '記録がない場合' do
      it '0を返すこと' do
        result = BadgeService.send(:calculate_max_consecutive_days, user)
        expect(result).to eq(0)
      end
    end

    context '記録が飛び飛びの場合' do
      before do
        # 現在、2日前、3日前に記録 -> 2日前と3日前が連続（2日間）
        create(:habit_record, user: user, habit: habit, recorded_at: Date.current, completed: true)
        create(:habit_record, user: user, habit: habit, recorded_at: Date.current - 2.days, completed: true)
        create(:habit_record, user: user, habit: habit, recorded_at: Date.current - 3.days, completed: true)
      end

      it '最大の連続日数を返すこと' do
        result = BadgeService.send(:calculate_max_consecutive_days, user)
        # 2日前と3日前が連続しているので2を返す
        expect(result).to eq(2)
      end
    end
  end

  describe '.calculate_completion_rate' do
    let(:user) { create(:user) }
    let(:habit) { create(:habit, user: user) }

    context '習慣がない場合' do
      it '0を返すこと' do
        result = BadgeService.send(:calculate_completion_rate, user)
        expect(result).to eq(0.0)
      end
    end

    context '記録がある場合' do
      before do
        # 過去31日間で15日記録 (15/31 = 48.4%)
        15.times do |i|
          create(:habit_record,
                 user: user,
                 habit: habit,
                 recorded_at: Date.current - i.days,
                 completed: true)
        end
      end

      it '完了率を正しく計算すること' do
        result = BadgeService.send(:calculate_completion_rate, user)
        expect(result).to eq(48.4)
      end
    end
  end
end
