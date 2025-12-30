module Admin
  class PostsController < Admin::BaseController
    def index
      @posts = Post.includes(:user, :habit, :likes).order(created_at: :desc)
    end

    def destroy
      @post = Post.find(params[:id])

      if @post.destroy
        redirect_to admin_posts_path, notice: '投稿を削除しました。'
      else
        redirect_to admin_posts_path, alert: '投稿の削除に失敗しました。'
      end
    end
  end
end
