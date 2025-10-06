class BadgesController < ApplicationController
  include BadgeChecker

  before_action :authenticate_user!

  def index
    @badges = Badge.active.includes(:users)
    @user_badges = current_user.user_badges.includes(:badge).recent.map(&:badge)

    Rails.logger.info "DEBUG: @user_badges = #{@user_badges.map(&:name)}"
  end

  def show
    @badge = Badge.find(params[:id])
    @users_with_badge = @badge.users.limit(10)
    @user_badge = current_user.user_badges.find_by(badge: @badge) if current_user.badge?(@badge)
  end
end
