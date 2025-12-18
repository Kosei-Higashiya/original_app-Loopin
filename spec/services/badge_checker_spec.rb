require 'rails_helper'

RSpec.describe BadgeChecker, type: :service do
  describe '.check_and_award_badges_for_user' do
    let(:user) { create(:user) }
    let(:habit) { create(:habit, user: user) }

    context '新しいバッジを獲得できる場合' do
      let!(:badge) { create(:badge, condition_type: 'total_records', condition_value: 3) }

      before do
        # 3つの記録を作成
        3.times do |i|
          create(:habit_record,
                 user: user,
                 habit: habit,
                 recorded_at: Date.current - i.days,
                 completed: true)
        end
      end

      it '新しいバッジを付与すること' do
        expect {
          BadgeChecker.check_and_award_badges_for_user(user)
        }.to change { user.user_badges.count }.by(1)
      end

      it '付与されたバッジを返すこと' do
        results = BadgeChecker.check_and_award_badges_for_user(user)
        expect(results[:newly_earned]).to include(badge)
        expect(results[:newly_earned].count).to eq(1)
      end

      it 'ユーザー統計情報を返すこと' do
        results = BadgeChecker.check_and_award_badges_for_user(user)
        expect(results[:stats]).to be_present
        expect(results[:stats][:total_records]).to eq(3)
      end
    end

    context 'すでにバッジを獲得している場合' do
      let!(:badge) { create(:badge, condition_type: 'total_records', condition_value: 1) }

      before do
        create(:habit_record, user: user, habit: habit, completed: true)
        # 先にバッジを付与
        UserBadge.award_badge(user, badge)
      end

      it '新しいバッジを付与しないこと' do
        expect {
          BadgeChecker.check_and_award_badges_for_user(user)
        }.not_to change { user.user_badges.count }
      end

      it '空の newly_earned を返すこと' do
        results = BadgeChecker.check_and_award_badges_for_user(user)
        expect(results[:newly_earned]).to be_empty
      end
    end

    context '条件を満たさない場合' do
      let!(:badge) { create(:badge, condition_type: 'total_records', condition_value: 10) }

      before do
        create(:habit_record, user: user, habit: habit, completed: true)
      end

      it 'バッジを付与しないこと' do
        expect {
          BadgeChecker.check_and_award_badges_for_user(user)
        }.not_to change { user.user_badges.count }
      end

      it '空の newly_earned を返すこと' do
        results = BadgeChecker.check_and_award_badges_for_user(user)
        expect(results[:newly_earned]).to be_empty
      end
    end

    context '非アクティブなバッジがある場合' do
      let!(:active_badge) { create(:badge, condition_type: 'total_records', condition_value: 1, active: true) }
      let!(:inactive_badge) { create(:badge, :inactive, condition_type: 'total_records', condition_value: 1) }

      before do
        create(:habit_record, user: user, habit: habit, completed: true)
      end

      it 'アクティブなバッジのみを付与すること' do
        results = BadgeChecker.check_and_award_badges_for_user(user)
        expect(results[:newly_earned]).to include(active_badge)
        expect(results[:newly_earned]).not_to include(inactive_badge)
      end
    end

    context '複数のバッジを同時に獲得できる場合' do
      let!(:badge1) { create(:badge, condition_type: 'total_records', condition_value: 3) }
      let!(:badge2) { create(:badge, condition_type: 'total_habits', condition_value: 1) }

      before do
        3.times do |i|
          create(:habit_record,
                 user: user,
                 habit: habit,
                 recorded_at: Date.current - i.days,
                 completed: true)
        end
      end

      it '複数のバッジを付与すること' do
        expect {
          BadgeChecker.check_and_award_badges_for_user(user)
        }.to change { user.user_badges.count }.by(2)
      end

      it 'すべての新しいバッジを返すこと' do
        results = BadgeChecker.check_and_award_badges_for_user(user)
        expect(results[:newly_earned]).to include(badge1, badge2)
      end
    end

    context 'エラーが発生した場合' do
      let!(:badge) { create(:badge, condition_type: 'total_records', condition_value: 1) }

      before do
        create(:habit_record, user: user, habit: habit, completed: true)
        # UserBadge.award_badge がエラーを発生させるようにモック
        allow(UserBadge).to receive(:award_badge).and_raise(StandardError, 'Test error')
      end

      it 'エラー情報を返すこと' do
        results = BadgeChecker.check_and_award_badges_for_user(user)
        expect(results[:errors]).not_to be_empty
        expect(results[:errors].first).to include('Test error')
      end

      it '処理が中断されないこと' do
        expect {
          BadgeChecker.check_and_award_badges_for_user(user)
        }.not_to raise_error
      end
    end
  end

  describe '.calculate_user_stats' do
    let(:user) { create(:user) }
    let(:habit) { create(:habit, user: user) }

    context 'ユーザーに習慣と記録がある場合' do
      before do
        # 過去30日間で15回完了した記録を作成
        15.times do |i|
          create(:habit_record,
                 user: user,
                 habit: habit,
                 recorded_at: Date.current - i.days,
                 completed: true)
        end
      end

      it '正しい統計情報を返すこと' do
        stats = BadgeChecker.send(:calculate_user_stats, user)

        expect(stats[:total_habits]).to eq(1)
        expect(stats[:total_records]).to eq(15)
        expect(stats[:completed_records]).to eq(15)
        expect(stats[:consecutive_days]).to eq(15)
        expect(stats[:completion_rate]).to be > 0
      end
    end

    context 'ユーザーに習慣がない場合' do
      it '完了率が0であること' do
        stats = BadgeChecker.send(:calculate_user_stats, user)

        expect(stats[:total_habits]).to eq(0)
        expect(stats[:completion_rate]).to eq(0.0)
      end
    end

    context '過去30日間の完了率を計算する場合' do
      before do
        # 過去30日間で15回完了した記録を作成
        15.times do |i|
          create(:habit_record,
                 user: user,
                 habit: habit,
                 recorded_at: Date.current - i.days,
                 completed: true)
        end
      end

      it '正しい完了率を計算すること' do
        stats = BadgeChecker.send(:calculate_user_stats, user)

        # 31日 × 1習慣 = 31の可能記録数のうち、15が完了 = 48.4%
        expect(stats[:completion_rate]).to eq(48.4)
      end
    end
  end

  describe '.calculate_max_consecutive_days' do
    let(:user) { create(:user) }
    let(:habit) { create(:habit, user: user) }

    context '連続した記録がある場合' do
      before do
        # 5日連続の記録を作成
        5.times do |i|
          create(:habit_record,
                 user: user,
                 habit: habit,
                 recorded_at: Date.current - i.days,
                 completed: true)
        end
      end

      it '正しい連続日数を返すこと' do
        consecutive_days = BadgeChecker.send(:calculate_max_consecutive_days, user)
        expect(consecutive_days).to eq(5)
      end
    end

    context '連続が途切れている記録がある場合' do
      before do
        # 3日連続
        3.times do |i|
          create(:habit_record,
                 user: user,
                 habit: habit,
                 recorded_at: Date.current - i.days,
                 completed: true)
        end

        # 2日空ける

        # さらに2日連続
        2.times do |i|
          create(:habit_record,
                 user: user,
                 habit: habit,
                 recorded_at: Date.current - (i + 5).days,
                 completed: true)
        end
      end

      it '最大の連続日数を返すこと' do
        consecutive_days = BadgeChecker.send(:calculate_max_consecutive_days, user)
        expect(consecutive_days).to eq(3)
      end
    end

    context '記録がない場合' do
      it '0を返すこと' do
        consecutive_days = BadgeChecker.send(:calculate_max_consecutive_days, user)
        expect(consecutive_days).to eq(0)
      end
    end

    context '1日だけ記録がある場合' do
      before do
        create(:habit_record,
               user: user,
               habit: habit,
               recorded_at: Date.current,
               completed: true)
      end

      it '1を返すこと' do
        consecutive_days = BadgeChecker.send(:calculate_max_consecutive_days, user)
        expect(consecutive_days).to eq(1)
      end
    end
  end

  describe '.calculate_completion_rate' do
    let(:user) { create(:user) }
    let(:habit) { create(:habit, user: user) }

    context '習慣がない場合' do
      before do
        user.habits.destroy_all
      end

      it '0を返すこと' do
        completion_rate = BadgeChecker.send(:calculate_completion_rate, user)
        expect(completion_rate).to eq(0.0)
      end
    end

    context '記録がある場合' do
      before do
        # 過去30日間で15回完了した記録を作成
        15.times do |i|
          create(:habit_record,
                 user: user,
                 habit: habit,
                 recorded_at: Date.current - i.days,
                 completed: true)
        end
      end

      it '正しい完了率を計算すること' do
        completion_rate = BadgeChecker.send(:calculate_completion_rate, user)

        # 31日 × 1習慣 = 31の可能記録数のうち、15が完了 = 48.4%
        expect(completion_rate).to eq(48.4)
      end
    end

    context '未完了の記録がある場合' do
      before do
        # 完了した記録
        10.times do |i|
          create(:habit_record,
                 user: user,
                 habit: habit,
                 recorded_at: Date.current - i.days,
                 completed: true)
        end

        # 未完了の記録
        5.times do |i|
          create(:habit_record,
                 user: user,
                 habit: habit,
                 recorded_at: Date.current - (i + 10).days,
                 completed: false)
        end
      end

      it '完了した記録のみをカウントすること' do
        completion_rate = BadgeChecker.send(:calculate_completion_rate, user)

        # 31日 × 1習慣 = 31の可能記録数のうち、10が完了 = 32.3%
        expect(completion_rate).to eq(32.3)
      end
    end

    context '複数の習慣がある場合' do
      let(:habit2) { create(:habit, user: user) }

      before do
        # 習慣1で10回完了
        10.times do |i|
          create(:habit_record,
                 user: user,
                 habit: habit,
                 recorded_at: Date.current - i.days,
                 completed: true)
        end

        # 習慣2で5回完了
        5.times do |i|
          create(:habit_record,
                 user: user,
                 habit: habit2,
                 recorded_at: Date.current - i.days,
                 completed: true)
        end
      end

      it '全習慣を含めた完了率を計算すること' do
        completion_rate = BadgeChecker.send(:calculate_completion_rate, user)

        # 31日 × 2習慣 = 62の可能記録数のうち、15が完了 = 24.2%
        expect(completion_rate).to eq(24.2)
      end
    end
  end

  describe '.calculate_rate_percentage' do
    it '正しいパーセンテージを計算すること' do
      rate = BadgeChecker.send(:calculate_rate_percentage, 15, 31)
      expect(rate).to eq(48.4)
    end

    it '100%を正しく計算すること' do
      rate = BadgeChecker.send(:calculate_rate_percentage, 10, 10)
      expect(rate).to eq(100.0)
    end

    it '0%を正しく計算すること' do
      rate = BadgeChecker.send(:calculate_rate_percentage, 0, 10)
      expect(rate).to eq(0.0)
    end

    it '小数点以下1桁に丸めること' do
      rate = BadgeChecker.send(:calculate_rate_percentage, 1, 3)
      expect(rate).to eq(33.3)
    end
  end
end
