class BadgesController < ApplicationController
  before_action :authenticate_user!

  def index
    @badges = Badge.active.includes(:users)
    @user_badges = current_user.user_badges.includes(:badge).recent.map(&:badge)
  end

  def show
    @badge = Badge.find(params[:id])
    @user_badge = current_user.user_badges.find_by(badge: @badge) if current_user.badge?(@badge)
  end
end
