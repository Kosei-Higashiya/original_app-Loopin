require 'rails_helper'

RSpec.describe "Posts API", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:habit) { create(:habit, user: user) }
  let(:other_habit) { create(:habit, user: other_user) }
  let!(:user_post) { create(:post, user: user, habit: habit) }
  let!(:other_user_post) { create(:post, user: other_user, habit: other_habit) }

  before do
    sign_in user
  end

  describe "GET /posts" do
    it "returns successful response" do
      get "/posts"
      expect(response).to have_http_status(:success)
    end

    it "displays posts content" do
      get "/posts"
      expect(response.body).to include('This is a test post about my habit')
    end

    context "with tag filter" do
      let(:tag) { create(:tag, name: 'motivation') }
      let!(:tagged_post) { create(:post, tags: [tag], content: 'Tagged post content') }

      it "filters posts by tag" do
        get "/posts", params: { tag: 'motivation' }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Tagged post content')
      end
    end
  end

  describe "GET /posts/liked" do
    let(:liked_post) { create(:post, content: 'I liked this post') }

    before do
      create(:like, user: user, post: liked_post)
    end

    it "returns a successful response" do
      get "/posts/liked"
      expect(response).to have_http_status(:success)
    end

    it "shows only liked posts" do
      get "/posts/liked"
      expect(response.body).to include('I liked this post')
      expect(response.body).not_to include('This is a test post about my habit') # user hasn't liked their own post
    end

    it "requires authentication" do
      sign_out user
      get "/posts/liked"
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "GET /posts/new" do
    it "returns successful response" do
      get "/posts/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /posts" do
    let(:valid_params) do
      { post: { habit_id: habit.id, content: 'New post content', tag_list: 'motivation, health' } }
    end

    let(:invalid_params) do
      { post: { habit_id: habit.id, content: '', tag_list: 'motivation' } }
    end

    context "with valid parameters" do
      it "creates a new post" do
        expect {
          post "/posts", params: valid_params
        }.to change(Post, :count).by(1)
      end

      it "redirects to posts index with success message" do
        post "/posts", params: valid_params
        expect(response).to redirect_to(posts_path)
        follow_redirect!
        expect(response.body).to include('投稿が作成されました。')
      end
    end

    context "with invalid parameters" do
      it "does not create a new post" do
        expect {
          post "/posts", params: invalid_params
        }.not_to change(Post, :count)
      end

      it "returns unprocessable entity status" do
        post "/posts", params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /posts/:id/edit" do
    context "when user owns the post" do
      it "returns successful response" do
        get "/posts/#{user_post.id}/edit"
        expect(response).to have_http_status(:success)
      end
    end

    context "when user does not own the post" do
      it "redirects with unauthorized message" do
        get "/posts/#{other_user_post.id}/edit"
        expect(response).to redirect_to(posts_path)
        follow_redirect!
        expect(response.body).to include('権限がありません。')
      end
    end
  end

  describe "PATCH /posts/:id" do
    let(:update_params) do
      { post: { content: 'Updated post content', tag_list: 'updated, tags' } }
    end

    let(:invalid_update_params) do
      { post: { content: '' } }
    end

    context "when user owns the post" do
      context "with valid parameters" do
        it "updates the post" do
          patch "/posts/#{user_post.id}", params: update_params
          user_post.reload
          expect(user_post.content).to eq('Updated post content')
        end

        it "redirects with success message" do
          patch "/posts/#{user_post.id}", params: update_params
          expect(response).to redirect_to(posts_path)
          follow_redirect!
          expect(response.body).to include('投稿が更新されました。')
        end
      end

      context "with invalid parameters" do
        it "does not update the post" do
          original_content = user_post.content
          patch "/posts/#{user_post.id}", params: invalid_update_params
          user_post.reload
          expect(user_post.content).to eq(original_content)
        end

        it "returns unprocessable entity status" do
          patch "/posts/#{user_post.id}", params: invalid_update_params
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "when user does not own the post" do
      it "redirects with unauthorized message" do
        patch "/posts/#{other_user_post.id}", params: update_params
        expect(response).to redirect_to(posts_path)
        follow_redirect!
        expect(response.body).to include('権限がありません。')
      end

      it "does not update the post" do
        original_content = other_user_post.content
        patch "/posts/#{other_user_post.id}", params: update_params
        other_user_post.reload
        expect(other_user_post.content).to eq(original_content)
      end
    end
  end

  describe "DELETE /posts/:id" do
    context "when user owns the post" do
      it "destroys the post" do
        expect {
          delete "/posts/#{user_post.id}"
        }.to change(Post, :count).by(-1)
      end

      it "redirects with success message" do
        delete "/posts/#{user_post.id}"
        expect(response).to redirect_to(posts_path)
        follow_redirect!
        expect(response.body).to include('投稿が削除されました。')
      end
    end

    context "when user does not own the post" do
      it "does not destroy the post" do
        expect {
          delete "/posts/#{other_user_post.id}"
        }.not_to change(Post, :count)
      end

      it "redirects with unauthorized message" do
        delete "/posts/#{other_user_post.id}"
        expect(response).to redirect_to(posts_path)
        follow_redirect!
        expect(response.body).to include('権限がありません。')
      end
    end
  end

  describe "authentication" do
    before { sign_out user }

    it "requires authentication for posts index" do
      get "/posts"
      expect(response).to redirect_to(new_user_session_path)
    end

    it "requires authentication for creating posts" do
      post "/posts", params: { post: { content: 'Test' } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it "requires authentication for editing posts" do
      get "/posts/#{user_post.id}/edit"
      expect(response).to redirect_to(new_user_session_path)
    end

    it "requires authentication for updating posts" do
      patch "/posts/#{user_post.id}", params: { post: { content: 'Updated' } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it "requires authentication for deleting posts" do
      delete "/posts/#{user_post.id}"
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end