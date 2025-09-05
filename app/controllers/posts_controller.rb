class PostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post, only: [:edit, :update, :destroy]

  def index
    @posts = Post.with_associations.recent.limit(50)
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
      respond_to do |format|
        format.html { redirect_to posts_path, notice: '投稿が削除されました。' }
        format.js   # This will render destroy.js.erb
      end
    else
      respond_to do |format|
        format.html { redirect_to posts_path, alert: '権限がありません。' }
        format.js   { render js: "alert('権限がありません。');" }
      end
    end
  end

  def edit
    if @post.user != current_user
      redirect_to posts_path, alert: '権限がありません。'
      return
    end
    @user_habits = current_user.habits.order(:title)
  end

  def update
    if @post.user != current_user
      redirect_to posts_path, alert: '権限がありません。'
      return
    end

    if @post.update(post_params)
      redirect_to posts_path, notice: '投稿が更新されました。'
    else
      @user_habits = current_user.habits.order(:title)
      render :edit, status: :unprocessable_entity
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