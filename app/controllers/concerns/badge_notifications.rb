# バッジ通知システム
module BadgeNotifications
  extend ActiveSupport::Concern

  private

  # バッジ獲得後に呼び出して通知をセッションに保存（重複を防ぐ）
  def set_badge_notification(badges)
    return if badges.blank?
    
    # 新しいバッジが追加されるので処理済みフラグをクリア
    clear_badge_notification_processed_flag
    
    session[:newly_earned_badges] ||= []

    badges.each do |badge|
      badge_data = { 'id' => badge.id, 'name' => badge.name }  # Use string keys consistently
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

  # 通知フラッシュメッセージを設定（重複防止機能付き）
  def set_badge_notification_flash
    # Turboリクエストやajaxリクエストではフラッシュしない
    return if request.format.turbo_stream? || request.xhr?
    
    # セッションに通知がない場合は何もしない
    unless session[:newly_earned_badges].present? && session[:newly_earned_badges].is_a?(Array) && session[:newly_earned_badges].any?
      return
    end
    
    # 既にこのリクエストでフラッシュが設定されている場合はスキップ（重複防止）
    return if flash[:success].present? && flash[:success].include?('バッジ')
    
    # セッションから通知を取得
    notifications = session[:newly_earned_badges].dup
    return if notifications.blank?

    # 既に処理済みかチェック（ただし、通知がある場合は一度だけ表示を許可）
    if badge_notification_already_processed?
      # セッションをクリアして今後の重複を防ぐ
      session.delete(:newly_earned_badges)
      session[:newly_earned_badges] = nil
      return
    end

    # フラッシュメッセージを設定
    flash[:success] = if notifications.size == 1
                        "🎉おめでとうございます! バッジ「#{notifications.first['name']}」を獲得しました！"
                      else
                        "🎉おめでとうございます! #{notifications.size}個のバッジを獲得しました！"
                      end

    # フラッシュ設定後にセッションをクリア（二重実行防止）
    session.delete(:newly_earned_badges)
    session[:newly_earned_badges] = nil
    
    # バッジ通知が処理済みであることを記録（後続のリクエストでは処理しない）
    session[:badge_notification_processed] = true
    
    Rails.logger.info "[BadgeNotifications] Flash set for badges: #{notifications.map { |n| n['name'] }.join(', ')}"
  end

  # バッジ通知が既に処理済みかチェック
  def badge_notification_already_processed?
    session[:badge_notification_processed] == true
  end

  # バッジ通知処理済みフラグをクリア（新しいバッジ獲得時に呼ぶ）
  def clear_badge_notification_processed_flag
    session.delete(:badge_notification_processed)
    session[:badge_notification_processed] = nil
  end
end
