# バッジ通知システム
module BadgeNotifications
  extend ActiveSupport::Concern

  private

  # バッジ獲得後に呼び出して通知をセッションに保存（重複を防ぐ）
  def set_badge_notification(badges)
    return if badges.blank?
    session[:newly_earned_badges] ||= []

    badges.each do |badge|
      badge_data = { id: badge.id, name: badge.name }
      unless session[:newly_earned_badges].any? { |b| b['id'] == badge.id }
        session[:newly_earned_badges] << badge_data
      end
    end

    Rails.logger.info "[BadgeNotifications] Stored badges in session: #{session[:newly_earned_badges].map { |b| b['name'] }.join(', ')}"
  end


  # 保存された通知を取得してクリア（デバッグログ付き）
  def get_and_clear_badge_notifications
    return [] unless session[:newly_earned_badges].present?
    
    notifications = session[:newly_earned_badges].dup
    
    # セッションをクリア
    session.delete(:newly_earned_badges)
    
    # セッションクリアを確実にするため、nilも設定
    session[:newly_earned_badges] = nil
    
    # デバッグログ
    Rails.logger.info "Badge notifications cleared from session: #{notifications.map { |n| n['name'] }.join(', ')}" if notifications.any?
    notifications
  end

  # 通知フラッシュメッセージを設定（デバッグログ付き）
  def set_badge_notification_flash
    # Turboリクエストやajaxリクエストではフラッシュしない
    return if request.format.turbo_stream? || request.xhr?
    
    # セッションに通知がない場合は何もしない
    return unless session[:newly_earned_badges].present?
    
    # フラッシュが既に設定されている場合はスキップ（重複防止）
    return if flash[:success].present? && flash[:success].include?('バッジ')
    
    notifications = get_and_clear_badge_notifications
    return if notifications.blank?

    flash[:success] = if notifications.size == 1
                        "🎉おめでとうございます! バッジ「#{notifications.first['name']}」を獲得しました！"
                      else
                        "🎉おめでとうございます! #{notifications.size}個のバッジを獲得しました！"
                      end
    Rails.logger.info "[BadgeNotifications] Flash set for badges: #{notifications.map { |n| n['name'] }.join(', ')}"
  end
end
