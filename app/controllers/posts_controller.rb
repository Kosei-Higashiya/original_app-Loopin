class PostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post, only: [:show, :destroy]

  def index
    @posts = Post.with_associations.recent.limit(50)
  end

  def show
  end

  def new
    @post = current_user.posts.build
    @user_habits = current_user.habits.order(:title)
  end

  def create
    @post = current_user.posts.build(post_params)

    if @post.save
      redirect_to posts_path, notice: '投稿が作成されました。'
    else
      @user_habits = current_user.habits.order(:title)
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    if @post.user == current_user
      @post.destroy
      redirect_to posts_path, notice: '投稿が削除されました。'
    else
      redirect_to posts_path, alert: '権限がありません。'
    end
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:habit_id, :content, :image)
  end
end