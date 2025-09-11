class BadgesController < ApplicationController
  before_action :authenticate_user!

  def index
    @badges = Badge.active.includes(:users)
    @user_badges = current_user.user_badges.includes(:badge).recent
  end

  def show
    @badge = Badge.find(params[:id])
    @users_with_badge = @badge.users.limit(10)
  end

  # 手動でバッジチェックを実行（開発用）
  def check_awards
    current_user.check_and_award_badges
    redirect_to badges_path, notice: 'バッジの確認が完了しました。'
  end
end