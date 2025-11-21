require 'rails_helper'

RSpec.describe HabitsHelper, type: :helper do
  describe '#habit_current_streak' do
    let(:user) { create(:user) }
    let(:habit) { create(:habit, user: user) }

    context '記録がない場合' do
      it '0を返すこと' do
        expect(helper.habit_current_streak(habit)).to eq(0)
      end
    end

    context '今日だけ記録がある場合' do
      before do
        create(:habit_record, habit: habit, user: user, recorded_at: Date.current, completed: true)
      end

      it '1を返すこと' do
        expect(helper.habit_current_streak(habit)).to eq(1)
      end
    end

    context '今日と昨日の連続記録がある場合' do
      before do
        create(:habit_record, habit: habit, user: user, recorded_at: Date.current, completed: true)
        create(:habit_record, habit: habit, user: user, recorded_at: Date.current - 1.day, completed: true)
      end

      it '2を返すこと' do
        expect(helper.habit_current_streak(habit)).to eq(2)
      end
    end

    context '3日連続記録がある場合' do
      before do
        create(:habit_record, habit: habit, user: user, recorded_at: Date.current, completed: true)
        create(:habit_record, habit: habit, user: user, recorded_at: Date.current - 1.day, completed: true)
        create(:habit_record, habit: habit, user: user, recorded_at: Date.current - 2.days, completed: true)
      end

      it '3を返すこと' do
        expect(helper.habit_current_streak(habit)).to eq(3)
      end
    end

    context '昨日だけ記録がある場合（今日はまだ記録していない）' do
      before do
        create(:habit_record, habit: habit, user: user, recorded_at: Date.current - 1.day, completed: true)
      end

      it '1を返すこと' do
        expect(helper.habit_current_streak(habit)).to eq(1)
      end
    end

    context '昨日と一昨日の連続記録がある場合（今日はまだ記録していない）' do
      before do
        create(:habit_record, habit: habit, user: user, recorded_at: Date.current - 1.day, completed: true)
        create(:habit_record, habit: habit, user: user, recorded_at: Date.current - 2.days, completed: true)
      end

      it '2を返すこと' do
        expect(helper.habit_current_streak(habit)).to eq(2)
      end
    end

    context '連続記録が途切れている場合' do
      before do
        create(:habit_record, habit: habit, user: user, recorded_at: Date.current, completed: true)
        create(:habit_record, habit: habit, user: user, recorded_at: Date.current - 1.day, completed: true)
        # 2日前は記録なし
        create(:habit_record, habit: habit, user: user, recorded_at: Date.current - 3.days, completed: true)
      end

      it '連続している2日分のみカウントすること' do
        expect(helper.habit_current_streak(habit)).to eq(2)
      end
    end

    context '2日前まで記録があり、昨日と今日は記録がない場合' do
      before do
        create(:habit_record, habit: habit, user: user, recorded_at: Date.current - 2.days, completed: true)
        create(:habit_record, habit: habit, user: user, recorded_at: Date.current - 3.days, completed: true)
      end

      it '0を返すこと（ストリークが途切れている）' do
        expect(helper.habit_current_streak(habit)).to eq(0)
      end
    end

    context '未完了の記録が含まれている場合' do
      before do
        create(:habit_record, habit: habit, user: user, recorded_at: Date.current, completed: true)
        create(:habit_record, habit: habit, user: user, recorded_at: Date.current - 1.day, completed: false)
        create(:habit_record, habit: habit, user: user, recorded_at: Date.current - 2.days, completed: true)
      end

      it '完了した記録のみをカウントすること' do
        expect(helper.habit_current_streak(habit)).to eq(1)
      end
    end

    context '7日連続記録がある場合' do
      before do
        (0..6).each do |days_ago|
          create(:habit_record, habit: habit, user: user, recorded_at: Date.current - days_ago.days, completed: true)
        end
      end

      it '7を返すこと' do
        expect(helper.habit_current_streak(habit)).to eq(7)
      end
    end
  end
end
