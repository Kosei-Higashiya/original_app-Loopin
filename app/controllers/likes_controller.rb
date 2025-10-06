class LikesController < ApplicationController
  before_action :authenticate_user!

  def create
    @post = Post.find(params[:post_id])
    @like = current_user.likes.build(post: @post)

    respond_to do |format|
      format.html { head :ok }
      if @like.save
        format.turbo_stream
      else
        format.turbo_stream { head :unprocessable_entity }
      end
    end
  end

  def destroy
    @post = Post.find(params[:post_id])
    @like = current_user.likes.find_by(post: @post)

    respond_to do |format|
      format.html { head :ok }
      if @like&.destroy
        format.turbo_stream
      else
        format.turbo_stream { head :unprocessable_entity }
      end
    end
  end
end
