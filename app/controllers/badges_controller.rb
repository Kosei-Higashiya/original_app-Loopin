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
    begin
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
      
      # 現在のユーザーが持っているバッジを確認
      current_badges = current_user.badges.pluck(:name)
      all_badges = Badge.active.pluck(:name)
      
      # バッジチェックを実行
      newly_earned_badges = current_user.check_and_award_badges
      
      if newly_earned_badges.any?
        # 直接フラッシュメッセージを設定（セッション方式の問題を回避）
        if newly_earned_badges.size == 1
          flash[:success] = "🎉 おめでとうございます！バッジ「#{newly_earned_badges.first.name}」を獲得しました！"
        else
          flash[:success] = "🎉 おめでとうございます！#{newly_earned_badges.size}個のバッジを獲得しました！"
        end
        
        # セッション方式も並行して試す
        set_badge_notification(newly_earned_badges)
        
        redirect_to badges_path
      else
        # より詳細なデバッグ情報を表示
        debug_info = "バッジチェック完了 | 統計: 習慣#{user_stats[:total_habits]}個, 記録#{user_stats[:total_records]}個, 完了率#{user_stats[:completion_rate]}% | "
        debug_info += "既存バッジ: #{current_badges.join(', ').presence || 'なし'} | "
        debug_info += "利用可能バッジ: #{all_badges.join(', ')} | "
        debug_info += "テストバッジ作成: #{test_badge.persisted? ? '成功' : '失敗'}"
        
        redirect_to badges_path, notice: debug_info
      end
      
    rescue => e
      # エラーが発生した場合の詳細情報
      redirect_to badges_path, alert: "バッジチェック中にエラーが発生しました: #{e.message}"
    end
  end
end
