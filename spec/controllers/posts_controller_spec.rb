require 'rails_helper'

RSpec.describe PostsController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:habit) { create(:habit, user: user) }
  let(:other_habit) { create(:habit, user: other_user) }
  let!(:post) { create(:post, user: user, habit: habit) }
  let!(:other_post) { create(:post, user: other_user, habit: other_habit) }

  before do
    sign_in user
  end

  describe "GET #index" do
    context "without parameters" do
      it "returns a successful response" do
        get :index
        expect(response).to be_successful
      end

      it "assigns @posts with recent posts limited to 50" do
        get :index
        expect(assigns(:posts)).to include(post, other_post)
        expect(assigns(:posts).count).to be <= 50
      end

      it "orders posts by most recent" do
        newer_post = create(:post, created_at: 1.hour.ago)
        older_post = create(:post, created_at: 2.hours.ago)
        
        get :index
        expect(assigns(:posts).first.created_at).to be >= assigns(:posts).last.created_at
      end
    end

    context "with tag parameter" do
      let(:tag) { create(:tag, name: 'motivation') }
      let!(:tagged_post) { create(:post, tags: [tag]) }
      let!(:untagged_post) { create(:post) }

      it "filters posts by tag" do
        get :index, params: { tag: 'motivation' }
        expect(assigns(:posts)).to include(tagged_post)
        expect(assigns(:posts)).not_to include(untagged_post)
      end

      it "sets current_tag" do
        get :index, params: { tag: 'motivation' }
        expect(assigns(:current_tag)).to eq('motivation')
      end
    end

    context "with search query" do
      let!(:matching_post) { create(:post, content: 'This is about exercise') }
      let!(:non_matching_post) { create(:post, content: 'This is about cooking') }

      it "searches posts by content" do
        get :index, params: { q: { content_or_habit_title_or_tags_name_cont: 'exercise' } }
        expect(assigns(:posts)).to include(matching_post)
        expect(assigns(:posts)).not_to include(non_matching_post)
      end

      it "assigns ransack query object" do
        get :index, params: { q: { content_or_habit_title_or_tags_name_cont: 'exercise' } }
        expect(assigns(:q)).to be_present
      end
    end
  end

  describe "GET #liked" do
    let(:liked_post) { create(:post) }

    before do
      create(:like, user: user, post: liked_post)
    end

    it "returns a successful response" do
      get :liked
      expect(response).to be_successful
    end

    it "assigns posts liked by current user" do
      get :liked
      expect(assigns(:posts)).to include(liked_post)
      expect(assigns(:posts)).not_to include(post) # user hasn't liked their own post
    end
  end

  describe "GET #new" do
    it "returns a successful response" do
      get :new
      expect(response).to be_successful
    end

    it "assigns a new post for current user" do
      get :new
      expect(assigns(:post)).to be_a_new(Post)
      expect(assigns(:post).user).to eq(user)
    end

    it "assigns user habits ordered by title" do
      habit_b = create(:habit, user: user, title: 'B Habit')
      habit_a = create(:habit, user: user, title: 'A Habit')
      
      get :new
      expect(assigns(:user_habits)).to eq([habit_a, habit, habit_b])
    end
  end

  describe "POST #create" do
    let(:valid_attributes) do
      { habit_id: habit.id, content: 'This is a test post', tag_list: 'motivation, health' }
    end

    let(:invalid_attributes) do
      { habit_id: habit.id, content: '', tag_list: 'motivation' }
    end

    context "with valid attributes" do
      it "creates a new post" do
        expect {
          post :create, params: { post: valid_attributes }
        }.to change(Post, :count).by(1)
      end

      it "assigns the post to current user" do
        post :create, params: { post: valid_attributes }
        expect(assigns(:post).user).to eq(user)
      end

      it "redirects to posts path with success notice" do
        post :create, params: { post: valid_attributes }
        expect(response).to redirect_to(posts_path)
        expect(flash[:notice]).to eq('投稿が作成されました。')
      end
    end

    context "with invalid attributes" do
      it "does not create a new post" do
        expect {
          post :create, params: { post: invalid_attributes }
        }.not_to change(Post, :count)
      end

      it "renders the new template with unprocessable_entity status" do
        post :create, params: { post: invalid_attributes }
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "assigns user habits for the form" do
        post :create, params: { post: invalid_attributes }
        expect(assigns(:user_habits)).to be_present
      end
    end
  end

  describe "GET #edit" do
    context "when user owns the post" do
      it "returns a successful response" do
        get :edit, params: { id: post.id }
        expect(response).to be_successful
      end

      it "assigns the requested post" do
        get :edit, params: { id: post.id }
        expect(assigns(:post)).to eq(post)
      end

      it "assigns user habits ordered by title" do
        get :edit, params: { id: post.id }
        expect(assigns(:user_habits)).to be_present
      end
    end

    context "when user does not own the post" do
      it "redirects to posts path with alert" do
        get :edit, params: { id: other_post.id }
        expect(response).to redirect_to(posts_path)
        expect(flash[:alert]).to eq('権限がありません。')
      end
    end
  end

  describe "PATCH #update" do
    let(:new_attributes) do
      { content: 'Updated content', tag_list: 'updated, tags' }
    end

    let(:invalid_attributes) do
      { content: '' }
    end

    context "when user owns the post" do
      context "with valid attributes" do
        it "updates the post" do
          patch :update, params: { id: post.id, post: new_attributes }
          post.reload
          expect(post.content).to eq('Updated content')
        end

        it "redirects to posts path with success notice" do
          patch :update, params: { id: post.id, post: new_attributes }
          expect(response).to redirect_to(posts_path)
          expect(flash[:notice]).to eq('投稿が更新されました。')
        end
      end

      context "with invalid attributes" do
        it "does not update the post" do
          original_content = post.content
          patch :update, params: { id: post.id, post: invalid_attributes }
          post.reload
          expect(post.content).to eq(original_content)
        end

        it "renders the edit template with unprocessable_entity status" do
          patch :update, params: { id: post.id, post: invalid_attributes }
          expect(response).to render_template(:edit)
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "assigns user habits for the form" do
          patch :update, params: { id: post.id, post: invalid_attributes }
          expect(assigns(:user_habits)).to be_present
        end
      end
    end

    context "when user does not own the post" do
      it "redirects to posts path with alert" do
        patch :update, params: { id: other_post.id, post: new_attributes }
        expect(response).to redirect_to(posts_path)
        expect(flash[:alert]).to eq('権限がありません。')
      end

      it "does not update the post" do
        original_content = other_post.content
        patch :update, params: { id: other_post.id, post: new_attributes }
        other_post.reload
        expect(other_post.content).to eq(original_content)
      end
    end
  end

  describe "DELETE #destroy" do
    context "when user owns the post" do
      it "destroys the post" do
        expect {
          delete :destroy, params: { id: post.id }
        }.to change(Post, :count).by(-1)
      end

      it "redirects to posts path with success notice" do
        delete :destroy, params: { id: post.id }
        expect(response).to redirect_to(posts_path)
        expect(flash[:notice]).to eq('投稿が削除されました。')
      end
    end

    context "when user does not own the post" do
      it "does not destroy the post" do
        expect {
          delete :destroy, params: { id: other_post.id }
        }.not_to change(Post, :count)
      end

      it "redirects to posts path with alert" do
        delete :destroy, params: { id: other_post.id }
        expect(response).to redirect_to(posts_path)
        expect(flash[:alert]).to eq('権限がありません。')
      end
    end
  end

  describe "authentication" do
    context "when user is not signed in" do
      before { sign_out user }

      it "redirects to sign in page for index" do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end

      it "redirects to sign in page for new" do
        get :new
        expect(response).to redirect_to(new_user_session_path)
      end

      it "redirects to sign in page for create" do
        post :create, params: { post: { content: 'Test' } }
        expect(response).to redirect_to(new_user_session_path)
      end

      it "redirects to sign in page for edit" do
        get :edit, params: { id: post.id }
        expect(response).to redirect_to(new_user_session_path)
      end

      it "redirects to sign in page for update" do
        patch :update, params: { id: post.id, post: { content: 'Updated' } }
        expect(response).to redirect_to(new_user_session_path)
      end

      it "redirects to sign in page for destroy" do
        delete :destroy, params: { id: post.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end