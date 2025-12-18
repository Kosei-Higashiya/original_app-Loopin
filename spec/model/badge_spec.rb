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
end
