module BadgeNotifications
  extend ActiveSupport::Concern

  private

  # バッジ獲得後に呼び出して通知をセッションに保存
  def set_badge_notification(badges)
    return if badges.blank?
    
    session[:newly_earned_badges] ||= []
    badges.each do |badge|
      session[:newly_earned_badges] << {
        id: badge.id,
        name: badge.name
      }
    end
  end

  # 保存された通知を取得してクリア
  def get_and_clear_badge_notifications
    return [] unless session[:newly_earned_badges].present?
    
    notifications = session[:newly_earned_badges]
    session.delete(:newly_earned_badges)
    notifications
  end

  # 通知フラッシュメッセージを設定
  def set_badge_notification_flash
    notifications = get_and_clear_badge_notifications
    return if notifications.blank?

    if notifications.size == 1
      flash[:success] = "おめでとうございます、バッジ「#{notifications.first['name']}」を獲得しました！"
    else
      flash[:success] = "おめでとうございます、#{notifications.size}個のバッジを獲得しました！"
    end
  end
end