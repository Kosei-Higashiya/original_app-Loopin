require 'rails_helper'

RSpec.describe Post, type: :model do
  let(:user) { create(:user) }
  let(:habit) { create(:habit, user: user) }
  let(:post) { create(:post, user: user, habit: habit) }

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:habit) }
    it { should have_many(:post_tags).dependent(:destroy) }
    it { should have_many(:tags).through(:post_tags) }
    it { should have_many(:likes).dependent(:destroy) }
    it { should have_many(:liked_by_users).through(:likes) }
  end

  describe 'validations' do
    it { should validate_presence_of(:content) }
    it { should validate_length_of(:content).is_at_most(1000) }
  end

  describe 'scopes' do
    let!(:post1) { create(:post, created_at: 2.days.ago) }
    let!(:post2) { create(:post, created_at: 1.day.ago) }
    let!(:post3) { create(:post, created_at: Time.current) }

    describe '.recent' do
      it 'orders posts by created_at in descending order' do
        expect(Post.recent).to eq([post3, post2, post1])
      end
    end

    describe '.with_associations' do
      it 'includes user, habit, and tags associations' do
        query = Post.with_associations
        expect(query.includes_values).to include(:user, :habit, :tags)
      end
    end

    describe '.tagged_with' do
      let(:tag) { create(:tag, name: 'motivation') }
      let!(:tagged_post) { create(:post, tags: [tag]) }
      let!(:untagged_post) { create(:post) }

      it 'returns posts with the specified tag' do
        expect(Post.tagged_with('motivation')).to include(tagged_post)
        expect(Post.tagged_with('motivation')).not_to include(untagged_post)
      end
    end
  end

  describe 'methods' do
    describe '#tag_list' do
      context 'when post has tags' do
        let(:tag1) { create(:tag, name: 'motivation') }
        let(:tag2) { create(:tag, name: 'health') }
        let(:tag3) { create(:tag, name: 'exercise') }
        let(:post_with_tags) do
          post = create(:post)
          post.tags = [tag1, tag2, tag3]
          post
        end

        it 'returns tags as comma-separated string' do
          expect(post_with_tags.tag_list).to eq('motivation, health, exercise')
        end
      end

      context 'when post has no tags' do
        it 'returns empty string' do
          expect(post.tag_list).to eq('')
        end
      end
    end

    describe '#tag_list=' do
      context 'with comma-separated tag names' do
        it 'creates and assigns tags' do
          post.tag_list = 'motivation, health, exercise'
          expect(post.tags.map(&:name)).to match_array(%w[motivation health exercise])
        end
      end

      context 'with tags that have extra spaces' do
        it 'strips whitespace from tag names' do
          post.tag_list = ' motivation , health , exercise '
          expect(post.tags.map(&:name)).to match_array(%w[motivation health exercise])
        end
      end

      context 'with duplicate tags' do
        it 'removes duplicate tags' do
          post.tag_list = 'motivation, health, motivation, exercise'
          expect(post.tags.map(&:name)).to match_array(%w[motivation health exercise])
        end
      end

      context 'with empty or blank tags' do
        it 'ignores empty tags' do
          post.tag_list = 'motivation, , health,, exercise'
          expect(post.tags.map(&:name)).to match_array(%w[motivation health exercise])
        end
      end

      context 'with existing tags in database' do
        let!(:existing_tag) { create(:tag, name: 'motivation') }

        it 'uses existing tags instead of creating new ones' do
          expect {
            post.tag_list = 'motivation, health'
          }.to change(Tag, :count).by(1) # only 'health' should be created
          
          expect(post.tags).to include(existing_tag)
        end
      end
    end

    describe '#liked_by?' do
      let(:liker) { create(:user) }
      
      context 'when user has liked the post' do
        before { create(:like, user: liker, post: post) }
        
        it 'returns true' do
          expect(post.liked_by?(liker)).to be true
        end
      end

      context 'when user has not liked the post' do
        it 'returns false' do
          expect(post.liked_by?(liker)).to be false
        end
      end

      context 'when user is nil' do
        it 'returns false' do
          expect(post.liked_by?(nil)).to be false
        end
      end
    end
  end

  describe 'Ransack configuration' do
    describe '.ransackable_attributes' do
      it 'allows searching by specific attributes' do
        expected_attributes = %w[content created_at id updated_at]
        expect(Post.ransackable_attributes).to match_array(expected_attributes)
      end
    end

    describe '.ransackable_associations' do
      it 'allows searching through specific associations' do
        expected_associations = %w[habit tags user]
        expect(Post.ransackable_associations).to match_array(expected_associations)
      end
    end
  end
end