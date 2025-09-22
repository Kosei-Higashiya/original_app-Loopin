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
      expect(badge.errors[:name]).to include("can't be blank")
    end

    it 'nameが一意であること' do
      create(:badge, name: '初回達成')
      badge.name = '初回達成'
      expect(badge).to_not be_valid
      expect(badge.errors[:name]).to include("has already been taken")
    end

    it 'nameが255文字以下であること' do
      badge.name = 'a' * 256
      expect(badge).to_not be_valid
      expect(badge.errors[:name]).to include("is too long (maximum is 255 characters)")
    end

    it 'condition_typeが必須であること' do
      badge.condition_type = nil
      expect(badge).to_not be_valid
      expect(badge.errors[:condition_type]).to include("can't be blank")
    end

    it 'condition_valueが必須であること' do
      badge.condition_value = nil
      expect(badge).to_not be_valid
      expect(badge.errors[:condition_value]).to include("can't be blank")
    end

    it 'condition_valueが正の数であること' do
      badge.condition_value = 0
      expect(badge).to_not be_valid
      expect(badge.errors[:condition_value]).to include("must be greater than 0")
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

  describe 'スコープ' do
    let!(:active_badge) { create(:badge, active: true) }
    let!(:inactive_badge) { create(:badge, :inactive) }

    it '.activeはアクティブなバッジのみ返すこと' do
      expect(Badge.active).to include(active_badge)
      expect(Badge.active).to_not include(inactive_badge)
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
end