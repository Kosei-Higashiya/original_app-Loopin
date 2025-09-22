require 'rails_helper'

RSpec.describe "Posts", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:habit) { create(:habit, user: user) }
  let(:other_habit) { create(:habit, user: other_user) }
  let!(:post) { create(:post, user: user, habit: habit) }
  let!(:other_post) { create(:post, user: other_user, habit: other_habit) }

  before do
    sign_in user
  end

  describe "GET /posts" do
    context "without parameters" do
      it "returns a successful response" do
        get posts_path
        expect(response).to have_http_status(:success)
      end

      it "displays recent posts" do
        get posts_path
        expect(response.body).to include(post.content)
        expect(response.body).to include(other_post.content)
      end
    end

    context "with tag parameter" do
      let(:tag) { create(:tag, name: 'motivation') }
      let!(:tagged_post) { create(:post, tags: [tag]) }
      let!(:untagged_post) { create(:post) }

      it "filters posts by tag" do
        get posts_path, params: { tag: 'motivation' }
        expect(response).to have_http_status(:success)
        expect(response.body).to include(tagged_post.content)
        expect(response.body).not_to include(untagged_post.content)
      end
    end

    context "with search query" do
      let!(:matching_post) { create(:post, content: 'This is about exercise') }
      let!(:non_matching_post) { create(:post, content: 'This is about cooking') }

      it "searches posts by content" do
        get posts_path, params: { q: { content_or_habit_title_or_tags_name_cont: 'exercise' } }
        expect(response).to have_http_status(:success)
        expect(response.body).to include(matching_post.content)
        expect(response.body).not_to include(non_matching_post.content)
      end
    end
  end

  describe "GET /posts/liked" do
    let(:liked_post) { create(:post) }

    before do
      create(:like, user: user, post: liked_post)
    end

    it "returns a successful response" do
      get liked_posts_path
      expect(response).to have_http_status(:success)
    end

    it "shows only liked posts" do
      get liked_posts_path
      expect(response.body).to include(liked_post.content)
      expect(response.body).not_to include(post.content) # user hasn't liked their own post
    end
  end

  describe "GET /posts/new" do
    it "returns a successful response" do
      get new_post_path
      expect(response).to have_http_status(:success)
    end

    it "renders new post form" do
      get new_post_path
      expect(response.body).to include('form')
    end
  end

  describe "POST /posts" do
    let(:valid_attributes) do
      { habit_id: habit.id, content: 'This is a test post', tag_list: 'motivation, health' }
    end

    let(:invalid_attributes) do
      { habit_id: habit.id, content: '', tag_list: 'motivation' }
    end

    context "with valid attributes" do
      it "creates a new post" do
        expect {
          post posts_path, params: { post: valid_attributes }
        }.to change(Post, :count).by(1)
      end

      it "redirects to posts path with success notice" do
        post posts_path, params: { post: valid_attributes }
        expect(response).to redirect_to(posts_path)
        follow_redirect!
        expect(response.body).to include('投稿が作成されました。')
      end
    end

    context "with invalid attributes" do
      it "does not create a new post" do
        expect {
          post posts_path, params: { post: invalid_attributes }
        }.not_to change(Post, :count)
      end

      it "renders the new template with unprocessable_entity status" do
        post posts_path, params: { post: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /posts/:id/edit" do
    context "when user owns the post" do
      it "returns a successful response" do
        get edit_post_path(post)
        expect(response).to have_http_status(:success)
      end

      it "renders edit form" do
        get edit_post_path(post)
        expect(response.body).to include('form')
      end
    end

    context "when user does not own the post" do
      it "redirects to posts path with alert" do
        get edit_post_path(other_post)
        expect(response).to redirect_to(posts_path)
        follow_redirect!
        expect(response.body).to include('権限がありません。')
      end
    end
  end

  describe "PATCH /posts/:id" do
    let(:new_attributes) do
      { content: 'Updated content', tag_list: 'updated, tags' }
    end

    let(:invalid_attributes) do
      { content: '' }
    end

    context "when user owns the post" do
      context "with valid attributes" do
        it "updates the post" do
          patch post_path(post), params: { post: new_attributes }
          post.reload
          expect(post.content).to eq('Updated content')
        end

        it "redirects to posts path with success notice" do
          patch post_path(post), params: { post: new_attributes }
          expect(response).to redirect_to(posts_path)
          follow_redirect!
          expect(response.body).to include('投稿が更新されました。')
        end
      end

      context "with invalid attributes" do
        it "does not update the post" do
          original_content = post.content
          patch post_path(post), params: { post: invalid_attributes }
          post.reload
          expect(post.content).to eq(original_content)
        end

        it "renders the edit template with unprocessable_entity status" do
          patch post_path(post), params: { post: invalid_attributes }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "when user does not own the post" do
      it "redirects to posts path with alert" do
        patch post_path(other_post), params: { post: new_attributes }
        expect(response).to redirect_to(posts_path)
        follow_redirect!
        expect(response.body).to include('権限がありません。')
      end

      it "does not update the post" do
        original_content = other_post.content
        patch post_path(other_post), params: { post: new_attributes }
        other_post.reload
        expect(other_post.content).to eq(original_content)
      end
    end
  end

  describe "DELETE /posts/:id" do
    context "when user owns the post" do
      it "destroys the post" do
        expect {
          delete post_path(post)
        }.to change(Post, :count).by(-1)
      end

      it "redirects to posts path with success notice" do
        delete post_path(post)
        expect(response).to redirect_to(posts_path)
        follow_redirect!
        expect(response.body).to include('投稿が削除されました。')
      end
    end

    context "when user does not own the post" do
      it "does not destroy the post" do
        expect {
          delete post_path(other_post)
        }.not_to change(Post, :count)
      end

      it "redirects to posts path with alert" do
        delete post_path(other_post)
        expect(response).to redirect_to(posts_path)
        follow_redirect!
        expect(response.body).to include('権限がありません。')
      end
    end
  end

  describe "authentication" do
    before { sign_out user }

    it "redirects unauthenticated users to sign in" do
      get posts_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "requires authentication for creating posts" do
      post '/posts', params: { post: { content: 'Test' } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it "requires authentication for editing posts" do
      get "/posts/#{post.id}/edit"
      expect(response).to redirect_to(new_user_session_path)
    end

    it "requires authentication for updating posts" do
      patch "/posts/#{post.id}", params: { post: { content: 'Updated' } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it "requires authentication for deleting posts" do
      delete "/posts/#{post.id}"
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end