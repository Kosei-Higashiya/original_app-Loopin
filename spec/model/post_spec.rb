require 'rails_helper'

RSpec.describe Post, type: :model do
  describe 'バリデーション' do
    let(:post) { build(:post) }

    it '有効なファクトリーを持つこと' do
      expect(post).to be_valid
    end

    it 'contentが必須であること' do
      post.content = nil
      expect(post).to_not be_valid
      expect(post.errors[:content]).to include('を入力してください')
    end

    it 'contentが1000文字以下であること' do
      post.content = 'a' * 1001
      expect(post).to_not be_valid
      expect(post.errors[:content]).to include('は1000文字以内で入力してください')
    end
  end

  describe 'アソシエーション' do
    it 'userと関連していること' do
      expect(Post.reflect_on_association(:user)).to be_present
      expect(Post.reflect_on_association(:user).macro).to eq(:belongs_to)
    end

    it 'habitと関連していること' do
      expect(Post.reflect_on_association(:habit)).to be_present
      expect(Post.reflect_on_association(:habit).macro).to eq(:belongs_to)
    end

    it 'likesと関連していること' do
      expect(Post.reflect_on_association(:likes)).to be_present
      expect(Post.reflect_on_association(:likes).macro).to eq(:has_many)
    end

    it 'tagsと関連していること' do
      expect(Post.reflect_on_association(:tags)).to be_present
      expect(Post.reflect_on_association(:tags).macro).to eq(:has_many)
    end
  end

  describe 'スコープ' do
    let!(:old_post) { create(:post, created_at: 1.week.ago) }
    let!(:new_post) { create(:post, created_at: 1.day.ago) }

    it '.recentは作成日時の降順で返すこと' do
      expect(Post.recent).to eq([new_post, old_post])
    end
  end

  describe '#liked_by?' do
    let(:post) { create(:post) }
    let(:user) { create(:user) }

    context 'ユーザーがいいねしている場合' do
      before { create(:like, user: user, post: post) }

      it 'trueを返すこと' do
        expect(post.liked_by?(user)).to be true
      end
    end

    context 'ユーザーがいいねしていない場合' do
      it 'falseを返すこと' do
        expect(post.liked_by?(user)).to be false
      end
    end

    context 'ユーザーがnilの場合' do
      it 'falseを返すこと' do
        expect(post.liked_by?(nil)).to be false
      end
    end
  end

  describe '#tag_list' do
    let(:post) { create(:post) }

    context 'タグがある場合' do
      before do
        tag1 = create(:tag, name: 'ランニング')
        tag2 = create(:tag, name: '健康')
        post.tags << [tag1, tag2]
      end

      it 'カンマ区切りのタグ名を返すこと' do
        expect(post.tag_list).to eq('ランニング, 健康')
      end
    end

    context 'タグがない場合' do
      it '空文字を返すこと' do
        expect(post.tag_list).to eq('')
      end
    end
  end

  describe '#tag_list=' do
    let(:post) { create(:post) }

    it 'カンマ区切りの文字列からタグを作成・関連付けすること' do
      post.tag_list = 'ランニング, 健康, フィットネス'
      post.save

      expect(post.tags.pluck(:name)).to match_array(%w[ランニング 健康 フィットネス])
    end

    it '重複するタグ名は除去されること' do
      post.tag_list = 'ランニング, ランニング, 健康'
      post.save

      expect(post.tags.pluck(:name)).to match_array(%w[ランニング 健康])
    end

    it '空白は除去されること' do
      post.tag_list = ' ランニング , 健康 , '
      post.save

      expect(post.tags.pluck(:name)).to match_array(%w[ランニング 健康])
    end
  end
end
