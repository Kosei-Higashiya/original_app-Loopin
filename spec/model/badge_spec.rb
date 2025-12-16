require 'rails_helper'

RSpec.describe Badge, type: :model do
  describe 'バリデーション' do
    let(:badge) { build(:badge) }

    it '有効なファクトリーを持つこと' do
      expect(badge).to be_valid
    end

    it 'nameが必須であること' do
      badge.name = nil
      expect(badge).to_not be_valid
      expect(badge.errors[:name]).to include('を入力してください')
    end

    it 'nameが一意であること' do
      create(:badge, name: '初回達成')
      badge.name = '初回達成'
      expect(badge).to_not be_valid
      expect(badge.errors[:name]).to include('はすでに存在します')
    end

    it 'nameが255文字以下であること' do
      badge.name = 'a' * 256
      expect(badge).to_not be_valid
      expect(badge.errors[:name]).to include('は255文字以内で入力してください')
    end

    it 'condition_typeが必須であること' do
      badge.condition_type = nil
      expect(badge).to_not be_valid
      expect(badge.errors[:condition_type]).to include('を入力してください')
    end

    it 'condition_valueが必須であること' do
      badge.condition_value = nil
      expect(badge).to_not be_valid
      expect(badge.errors[:condition_value]).to include('を入力してください')
    end

    it 'condition_valueが正の数であること' do
      badge.condition_value = 0
      expect(badge).to_not be_valid
      expect(badge.errors[:condition_value]).to include('は0より大きい値にしてください')
    end
  end

  describe 'アソシエーション' do
    it 'usersと関連していること' do
      expect(Badge.reflect_on_association(:users)).to be_present
      expect(Badge.reflect_on_association(:users).macro).to eq(:has_many)
    end

    it 'user_badgesと関連していること' do
      expect(Badge.reflect_on_association(:user_badges)).to be_present
      expect(Badge.reflect_on_association(:user_badges).macro).to eq(:has_many)
    end
  end

  describe '#condition_type_name' do
    it 'consecutive_daysの場合は連続日数を返すこと' do
      badge = create(:badge, :consecutive_days_badge)
      expect(badge.condition_type_name).to eq('連続日数')
    end

    it 'total_habitsの場合は習慣総数を返すこと' do
      badge = create(:badge, :total_habits_badge)
      expect(badge.condition_type_name).to eq('習慣総数')
    end

    it 'total_recordsの場合は記録総数を返すこと' do
      badge = create(:badge, condition_type: 'total_records')
      expect(badge.condition_type_name).to eq('記録総数')
    end

    it '未定義の条件タイプの場合はそのまま返すこと' do
      badge = create(:badge, condition_type: 'unknown_type')
      expect(badge.condition_type_name).to eq('unknown_type')
    end
  end

  describe '#earned_by?' do
    let(:user) { create(:user) }
    let(:habit) { create(:habit, user: user) }

    context 'consecutive_daysバッジの場合' do
      let(:badge) { create(:badge, :consecutive_days_badge, condition_value: 3) }

      it '連続日数が条件を満たす場合はtrueを返すこと' do
        3.times do |i|
          create(:habit_record,
                 user: user,
                 habit: habit,
                 recorded_at: Date.current - i.days,
                 completed: true)
        end

        expect(badge.earned_by?(user)).to be true
      end

      it '連続日数が条件を満たさない場合はfalseを返すこと' do
        create(:habit_record, user: user, habit: habit, completed: true)

        expect(badge.earned_by?(user)).to be false
      end
    end

    context 'total_habitsバッジの場合' do
      let(:badge) { create(:badge, :total_habits_badge, condition_value: 2) }

      it '習慣数が条件を満たす場合はtrueを返すこと' do
        create_list(:habit, 2, user: user)

        expect(badge.earned_by?(user)).to be true
      end

      it '習慣数が条件を満たさない場合はfalseを返すこと' do
        expect(badge.earned_by?(user)).to be false
      end
    end

    context 'total_recordsバッジの場合' do
      let(:badge) { create(:badge, condition_type: 'total_records', condition_value: 2) }

      it '記録数が条件を満たす場合はtrueを返すこと' do
        create_list(:habit_record, 2, user: user, habit: habit)

        expect(badge.earned_by?(user)).to be true
      end
    end

    context 'userがnilの場合' do
      let(:badge) { create(:badge) }

      it 'falseを返すこと' do
        expect(badge.earned_by?(nil)).to be false
      end
    end
  end

  describe '#earned_by_stats?' do
    context 'consecutive_daysバッジの場合' do
      let(:badge) { create(:badge, :consecutive_days_badge, condition_value: 7) }

      it '連続日数が条件を満たす場合はtrueを返すこと' do
        user_stats = { consecutive_days: 10, total_habits: 5, total_records: 20, completion_rate: 80.0 }
        expect(badge.earned_by_stats?(user_stats)).to be true
      end

      it '連続日数が条件を満たさない場合はfalseを返すこと' do
        user_stats = { consecutive_days: 5, total_habits: 5, total_records: 20, completion_rate: 80.0 }
        expect(badge.earned_by_stats?(user_stats)).to be false
      end

      it '連続日数がちょうど条件値と等しい場合はtrueを返すこと' do
        user_stats = { consecutive_days: 7, total_habits: 5, total_records: 20, completion_rate: 80.0 }
        expect(badge.earned_by_stats?(user_stats)).to be true
      end
    end

    context 'total_habitsバッジの場合' do
      let(:badge) { create(:badge, :total_habits_badge, condition_value: 5) }

      it '習慣数が条件を満たす場合はtrueを返すこと' do
        user_stats = { consecutive_days: 3, total_habits: 6, total_records: 20, completion_rate: 80.0 }
        expect(badge.earned_by_stats?(user_stats)).to be true
      end

      it '習慣数が条件を満たさない場合はfalseを返すこと' do
        user_stats = { consecutive_days: 3, total_habits: 3, total_records: 20, completion_rate: 80.0 }
        expect(badge.earned_by_stats?(user_stats)).to be false
      end
    end

    context 'total_recordsバッジの場合' do
      let(:badge) { create(:badge, condition_type: 'total_records', condition_value: 10) }

      it '記録数が条件を満たす場合はtrueを返すこと' do
        user_stats = { consecutive_days: 3, total_habits: 5, total_records: 15, completion_rate: 80.0 }
        expect(badge.earned_by_stats?(user_stats)).to be true
      end

      it '記録数が条件を満たさない場合はfalseを返すこと' do
        user_stats = { consecutive_days: 3, total_habits: 5, total_records: 5, completion_rate: 80.0 }
        expect(badge.earned_by_stats?(user_stats)).to be false
      end
    end

    context 'completion_rateバッジの場合' do
      let(:badge) { create(:badge, condition_type: 'completion_rate', condition_value: 75) }

      it '完了率が条件を満たす場合はtrueを返すこと' do
        user_stats = { consecutive_days: 3, total_habits: 5, total_records: 20, completion_rate: 80.0 }
        expect(badge.earned_by_stats?(user_stats)).to be true
      end

      it '完了率が条件を満たさない場合はfalseを返すこと' do
        user_stats = { consecutive_days: 3, total_habits: 5, total_records: 20, completion_rate: 60.0 }
        expect(badge.earned_by_stats?(user_stats)).to be false
      end
    end

    context 'user_statsが不正なデータ型または不明な条件タイプの場合' do
      let(:badge) { create(:badge) }

      it 'user_statsがHashでない場合はfalseを返すこと' do
        expect(badge.earned_by_stats?(nil)).to be false
        expect(badge.earned_by_stats?('string')).to be false
        expect(badge.earned_by_stats?(123)).to be false
      end

      it '不明なcondition_typeの場合はfalseを返すこと' do
        badge = create(:badge, condition_type: 'unknown_type', condition_value: 10)
        user_stats = { consecutive_days: 3, total_habits: 5, total_records: 20, completion_rate: 80.0 }
        expect(badge.earned_by_stats?(user_stats)).to be false
      end
    end
  end
end
