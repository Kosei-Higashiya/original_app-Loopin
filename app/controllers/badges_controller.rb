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
      Rails.logger.info "Badge check started for user #{current_user.id}"
      
      # まずテスト用バッジが存在するか確認し、なければ作成
      test_badge = Badge.find_by(name: "テスト用バッジ")
      if test_badge.nil?
        test_badge = Badge.create!(
          name: "テスト用バッジ",
          description: "バッジ機能をテストするためのバッジです",
          condition_type: "total_habits",
          condition_value: 0,  # 誰でも獲得できる条件
          icon: "🎉",
          active: true
        )
        Rails.logger.info "Test badge created: #{test_badge.id}"
      end

      # バッジチェックを実行（シンプルなバージョン）
      newly_earned_badges = []
      
      Badge.active.each do |badge|
        next if current_user.has_badge?(badge)
        
        if badge.earned_by?(current_user)
          user_badge = UserBadge.create!(
            user: current_user,
            badge: badge,
            earned_at: Time.current
          )
          newly_earned_badges << badge
          Rails.logger.info "Badge awarded: #{badge.name} to user #{current_user.id}"
        end
      end
      
      if newly_earned_badges.any?
        if newly_earned_badges.size == 1
          flash[:success] = "🎉 おめでとうございます！バッジ「#{newly_earned_badges.first.name}」を獲得しました！"
        else
          flash[:success] = "🎉 おめでとうございます！#{newly_earned_badges.size}個のバッジを獲得しました！"
        end
      else
        # 統計情報をシンプルに表示
        total_habits = current_user.habits.count
        total_badges = current_user.badges.count
        flash[:info] = "バッジチェック完了！現在の統計: 習慣#{total_habits}個、獲得バッジ#{total_badges}個"
      end
      
      redirect_to badges_path
      
    rescue => e
      Rails.logger.error "Badge check error: #{e.message}\n#{e.backtrace.join("\n")}"
      redirect_to badges_path, alert: "バッジチェック中にエラーが発生しました。しばらくしてからもう一度お試しください。"
    end
  end
end
