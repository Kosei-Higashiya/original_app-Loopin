# 

class LikesController < ApplicationController
  before_action :authenticate_user!

  def create
    @post = Post.find(params[:post_id])
    @like = current_user.likes.build(post: @post)

    respond_to do |format|
      if @like.save
        format.html { redirect_back(fallback_location: posts_path) }
        format.turbo_stream
      else
        format.html { redirect_back(fallback_location: posts_path, alert: 'いいねに失敗しました。') }
        format.turbo_stream { head :unprocessable_entity }
      end
    end
  end

  def destroy
    @post = Post.find(params[:post_id])
    @like = current_user.likes.find_by(post: @post)

    respond_to do |format|
      if @like&.destroy
        format.html { redirect_back(fallback_location: posts_path) }
        format.turbo_stream
      else
        format.html { redirect_back(fallback_location: posts_path, alert: 'いいね解除に失敗しました。') }
        format.turbo_stream { head :unprocessable_entity }
      end
    end
  end
end
