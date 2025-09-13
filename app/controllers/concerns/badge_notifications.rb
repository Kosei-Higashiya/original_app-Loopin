module BadgeNotifications
  extend ActiveSupport::Concern

  private

  # バッジ獲得後に呼び出して通知をセッションに保存（重複を防ぐ）
  def set_badge_notification(badges)
    return if badges.blank?

    session[:newly_earned_badges] ||= []
    
    badges.each do |badge|
      badge_data = {
        id: badge.id,
        name: badge.name
      }
      
      # 重複チェック - 同じIDのバッジが既に存在する場合は追加しない
      unless session[:newly_earned_badges].any? { |existing| existing['id'] == badge.id }
        session[:newly_earned_badges] << badge_data
      end
    end
  end

  # 保存された通知を取得してクリア（デバッグログ付き）
  def get_and_clear_badge_notifications
    return [] unless session[:newly_earned_badges].present?

    notifications = session[:newly_earned_badges].dup
    
    # セッションをクリア（通知表示フラグもクリア）
    session.delete(:newly_earned_badges)
    session.delete(:badge_notifications_displayed)
    
    # デバッグログ
    Rails.logger.info "Badge notifications cleared from session: #{notifications.map { |n| n['name'] }.join(', ')}" if notifications.any?
    
    notifications
  end

  # 通知フラッシュメッセージを設定（デバッグログ付き）
  def set_badge_notification_flash
    # 重複表示を防ぐため、同一リクエスト内で既に表示済みかチェック
    return if session[:badge_notifications_displayed] == request.request_id
    
    notifications = get_and_clear_badge_notifications
    return if notifications.blank?

    # デバッグログ
    Rails.logger.info "Setting badge notification flash for #{notifications.size} badge(s): #{notifications.map { |n| n['name'] }.join(', ')} (request_id: #{request.request_id})"

    if notifications.size == 1
      flash[:success] = "🎉おめでとうございます! バッジ「#{notifications.first['name']}」を獲得しました！"
    else
      flash[:success] = "🎉おめでとうございます! #{notifications.size}個のバッジを獲得しました！"
    end
    
    # 同一リクエストでの重複表示を防ぐフラグを設定
    session[:badge_notifications_displayed] = request.request_id
  end
end
