class BadgesController < ApplicationController
  before_action :authenticate_user!

  def index
    @badges = Badge.active.includes(:users)
    @user_badges = current_user.user_badges.includes(:badge).recent
  end

  def show
    @badge = Badge.find(params[:id])
    @users_with_badge = @badge.users.limit(10)
    @user_badge = current_user.user_badges.find_by(badge: @badge) if current_user.has_badge?(@badge)
  end

  # 手動でバッジチェックを実行（開発用）
  def check_awards
    # テスト用の簡単なバッジを作成（まだ存在しない場合）
    test_badge = Badge.find_or_create_by!(name: "テスト用バッジ") do |badge|
      badge.description = "バッジ機能をテストするためのバッジです"
      badge.condition_type = "total_habits"
      badge.condition_value = 0  # 誰でも獲得できる条件
      badge.icon = "🎉"
      badge.active = true
    end

    # デバッグ情報を収集
    user_stats = {
      total_habits: current_user.habits.count,
      total_records: current_user.habit_records.count,
      completed_records: current_user.habit_records.where(completed: true).count,
      max_consecutive_days: current_user.max_consecutive_days,
      completion_rate: current_user.overall_completion_rate
    }
    
    # バッジチェックを実行
    newly_earned_badges = current_user.check_and_award_badges
    
    if newly_earned_badges.any?
      # 直接フラッシュメッセージを設定（セッション方式の問題を回避）
      if newly_earned_badges.size == 1
        flash[:success] = "おめでとうございます、バッジ「#{newly_earned_badges.first.name}」を獲得しました！"
      else
        flash[:success] = "おめでとうございます、#{newly_earned_badges.size}個のバッジを獲得しました！"
      end
      
      # セッション方式も並行して試す
      set_badge_notification(newly_earned_badges)
      
      redirect_to badges_path
    else
      # デバッグ情報を表示
      redirect_to badges_path, notice: "バッジチェック完了。統計: 習慣#{user_stats[:total_habits]}個、記録#{user_stats[:total_records]}個、完了率#{user_stats[:completion_rate]}%、最大連続#{user_stats[:max_consecutive_days]}日。新しいバッジは獲得されませんでした。"
    end
  end
end
