class PostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post, only: %i[edit update destroy]

  def index
    @q = Post.ransack(params[:q])

    if params[:tag].present?
      @posts = Post.tagged_with(params[:tag]).with_associations.recent.limit(50)
      @current_tag = params[:tag]
    elsif params[:q].present? && params[:q][:content_or_habit_title_or_tags_name_cont].present?
      @posts = @q.result(distinct: true).with_associations.recent.limit(50)
    else
      @posts = Post.with_associations.recent.limit(50)
    end
  end

  def liked
    @posts = current_user.liked_posts.with_associations.recent.limit(50)
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
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to posts_path, alert: '権限がありません。' }
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend('flash', partial: 'shared/flash', locals: { alert: '権限がありません。' })
        end
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
    params.require(:post).permit(:habit_id, :content, :tag_list)
  end
end
