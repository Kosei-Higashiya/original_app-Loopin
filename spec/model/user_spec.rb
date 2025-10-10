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
      expect(user.errors[:email]).to include('を入力してください')
    end

    it 'emailが一意であること' do
      create(:user, email: 'test@example.com')
      user.email = 'test@example.com'
      expect(user).to_not be_valid
      expect(user.errors[:email]).to include('はすでに存在します')
    end

    it 'passwordが最低6文字であること' do
      user.password = '12345'
      user.password_confirmation = '12345'
      expect(user).to_not be_valid
      expect(user.errors[:password]).to include('は6文字以上で入力してください')
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
        expect(user.display_name).to eq('山田太郎')
      end
    end

    context '名前がない場合' do
      let(:user) { build(:user, :guest) }

      it 'ゲストを返すこと' do
        expect(user.display_name).to eq('ゲスト')
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

  describe '.from_omniauth' do
    let(:auth) do
      OmniAuth::AuthHash.new({
        provider: 'google_oauth2',
        uid: '123456789',
        info: {
          email: 'test@example.com',
          name: 'Test User'
        }
      })
    end

    context '新規ユーザーの場合' do
      it 'ユーザーを作成すること' do
        expect {
          User.from_omniauth(auth)
        }.to change(User, :count).by(1)
      end

      it '正しい情報でユーザーを作成すること' do
        user = User.from_omniauth(auth)
        expect(user.provider).to eq('google_oauth2')
        expect(user.uid).to eq('123456789')
        expect(user.email).to eq('test@example.com')
        expect(user.name).to eq('Test User')
      end
    end

    context '既にプロバイダーとUIDでユーザーが存在する場合' do
      let!(:existing_user) do
        create(:user, :oauth_user, 
               provider: 'google_oauth2', 
               uid: '123456789',
               email: 'test@example.com')
      end

      it '新しいユーザーを作成しないこと' do
        expect {
          User.from_omniauth(auth)
        }.not_to change(User, :count)
      end

      it '既存のユーザーを返すこと' do
        user = User.from_omniauth(auth)
        expect(user.id).to eq(existing_user.id)
      end
    end

    context '同じメールアドレスのユーザーが存在する場合' do
      let!(:existing_user) do
        create(:user, email: 'test@example.com', provider: nil, uid: nil)
      end

      it '新しいユーザーを作成しないこと' do
        expect {
          User.from_omniauth(auth)
        }.not_to change(User, :count)
      end

      it 'プロバイダーとUIDを既存ユーザーに追加すること' do
        user = User.from_omniauth(auth)
        expect(user.id).to eq(existing_user.id)
        expect(user.provider).to eq('google_oauth2')
        expect(user.uid).to eq('123456789')
      end
    end
  end

  describe '#password_required?' do
    context 'OAuth ユーザーの場合' do
      let(:oauth_user) { build(:user, :oauth_user) }

      it 'パスワードが不要であること' do
        expect(oauth_user.password_required?).to be_falsey
      end
    end

    context '通常のユーザーの場合' do
      let(:normal_user) { build(:user, provider: nil) }

      it 'パスワードが必要であること' do
        expect(normal_user.password_required?).to be_truthy
      end
    end
  end
end
