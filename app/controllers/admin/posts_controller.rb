module Admin
  class PostsController < Admin::BaseController
    def index
      @posts = Post.includes(:user, :habit).order(created_at: :desc)
    end

    def destroy
      @post = Post.find(params[:id])
      @post.destroy
      redirect_to admin_posts_path, notice: '投稿を削除しました。'
    end
  end
end
