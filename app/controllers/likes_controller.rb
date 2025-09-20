class LikesController < ApplicationController
  before_action :authenticate_user!

  def create
    @post = Post.find(params[:post_id])
    @like = current_user.likes.build(post: @post)

    if @like.save
      respond_to do |format|
        format.html { redirect_back(fallback_location: posts_path) }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_back(fallback_location: posts_path, alert: 'いいねに失敗しました。') }
        format.turbo_stream { render turbo_stream: turbo_stream.prepend('flash', partial: 'shared/flash', locals: { alert: 'いいねに失敗しました。' }) }
      end
    end
  end

  def destroy
    @post = Post.find(params[:post_id])
    @like = current_user.likes.find_by(post: @post)

    if @like&.destroy
      respond_to do |format|
        format.html { redirect_back(fallback_location: posts_path) }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_back(fallback_location: posts_path, alert: 'いいね解除に失敗しました。') }
        format.turbo_stream { render turbo_stream: turbo_stream.prepend('flash', partial: 'shared/flash', locals: { alert: 'いいね解除に失敗しました。' }) }
      end
    end
  end
end
