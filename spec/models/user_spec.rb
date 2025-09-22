require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'バリデーション' do
    let(:user) { build(:user) }

    it '有効なファクトリーを持つこと' do
      expect(user).to be_valid
    end

    it 'emailが必須であること' do
      user.email = nil
      expect(user).to_not be_valid
      expect(user.errors[:email]).to include("を入力してください")
    end

    it 'emailが一意であること' do
      create(:user, email: 'test@example.com')
      user.email = 'test@example.com'
      expect(user).to_not be_valid
      expect(user.errors[:email]).to include("はすでに存在します")
    end

    it 'passwordが最低6文字であること' do
      user.password = '12345'
      user.password_confirmation = '12345'
      expect(user).to_not be_valid
      expect(user.errors[:password]).to include("は6文字以上で入力してください")
    end
  end

  describe 'アソシエーション' do
    it 'habitsと関連していること' do
      expect(User.reflect_on_association(:habits)).to be_present
      expect(User.reflect_on_association(:habits).macro).to eq(:has_many)
    end

    it 'habit_recordsと関連していること' do
      expect(User.reflect_on_association(:habit_records)).to be_present
      expect(User.reflect_on_association(:habit_records).macro).to eq(:has_many)
    end

    it 'postsと関連していること' do
      expect(User.reflect_on_association(:posts)).to be_present
      expect(User.reflect_on_association(:posts).macro).to eq(:has_many)
    end

    it 'likesと関連していること' do
      expect(User.reflect_on_association(:likes)).to be_present
      expect(User.reflect_on_association(:likes).macro).to eq(:has_many)
    end

    it 'badgesと関連していること' do
      expect(User.reflect_on_association(:badges)).to be_present
      expect(User.reflect_on_association(:badges).macro).to eq(:has_many)
    end
  end

  describe '#display_name' do
    context '名前がある場合' do
      let(:user) { build(:user, :with_name) }

      it '名前を返すこと' do
        expect(user.display_name).to eq("山田太郎")
      end
    end

    context '名前がない場合' do
      let(:user) { build(:user, :guest) }

      it 'ゲストを返すこと' do
        expect(user.display_name).to eq("ゲスト")
      end
    end
  end

  describe '#max_consecutive_days' do
    let(:user) { create(:user) }
    let(:habit) { create(:habit, user: user) }

    context '連続した記録がある場合' do
      before do
        # 3日連続の記録を作成
        3.times do |i|
          create(:habit_record, 
                 user: user, 
                 habit: habit, 
                 recorded_at: Date.current - i.days,
                 completed: true)
        end
      end

      it '正しい連続日数を返すこと' do
        expect(user.max_consecutive_days).to eq(3)
      end
    end

    context '記録がない場合' do
      it '0を返すこと' do
        expect(user.max_consecutive_days).to eq(0)
      end
    end
  end

  describe '#overall_completion_rate' do
    let(:user) { create(:user) }
    let(:habit1) { create(:habit, user: user) }

    context '習慣がない場合' do
      it '0を返すこと' do
        expect(user.overall_completion_rate).to eq(0)
      end
    end

    context '記録がある場合' do
      before do
        # 過去30日間で15回完了した記録を作成
        15.times do |i|
          create(:habit_record,
                 user: user,
                 habit: habit1,
                 recorded_at: Date.current - i.days,
                 completed: true)
        end
      end

      it '完了率を正しく計算すること' do
        # 31日 × 1習慣 = 31の可能記録数のうち、15が完了 = 48.4%
        expect(user.overall_completion_rate).to eq(48.4)
      end
    end
  end
end