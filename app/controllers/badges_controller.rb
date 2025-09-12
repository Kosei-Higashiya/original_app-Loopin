class BadgesController < ApplicationController
  include BadgeChecker

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
     Rails.logger.info "[BadgesController] Badge check started for user #{current_user.id} at #{Time.current}"

    begin
       # Use optimized badge checker
      results = perform_badge_check_for_user(current_user)

      # Set appropriate flash messages
      if results[:newly_earned].any?
        if results[:newly_earned].size == 1
          flash[:success] = "🎉 おめでとうございます！バッジ「#{results[:newly_earned].first.name}」を獲得しました！"
        else
          flash[:success] = "おめでとうございます、#{results[:newly_earned].size}個のバッジを獲得しました！"
        end
      else
        stats = results[:stats]
        flash[:success] = "バッジチェック完了！現在の統計: 習慣#{stats[:total_habits]}個、獲得バッジ#{current_user.user_badges.count}個、記録#{stats[:total_records]}個（完了率#{stats[:completion_rate]}%）"
      end

       # Log any errors but don't fail the request
      if results[:errors].any?
        Rails.logger.warn "[BadgesController] Badge check had #{results[:errors].count} errors: #{results[:errors].join(', ')}"
        flash[:warning] = "一部のバッジのチェックでエラーが発生しましたが、処理は完了しました。"
      end

    rescue => e
      Rails.logger.error "[BadgesController] Badge check failed for user #{current_user.id}: #{e.message}"
      Rails.logger.error "[BadgesController] Backtrace: #{e.backtrace.first(5).join("\n")}"
      flash[:alert] = "バッジチェック中にエラーが発生しました。もう一度お試しください。"
    ensure
      # Always redirect to prevent hanging
      Rails.logger.info "[BadgesController] Redirecting to badges_path for user #{current_user.id}"
      redirect_to badges_path and return
    end
  end
end