# バッジ通知システム
module BadgeNotifications
  extend ActiveSupport::Concern

  private

  # バッジ獲得後に呼び出して通知をセッションに保存（重複を防ぐ）
  def badge_notification(badges)
    return if badges.blank?

    begin
      session[:newly_earned_badges] ||= []

      Rails.logger.debug do
        "[BadgeNotifications] Before adding, session contains: #{session[:newly_earned_badges].map do |b|
          b['name']
        end.join(', ')}"
      end

      badges.each do |badge|
        badge_data = { 'id' => badge.id, 'name' => badge.name }
        session[:newly_earned_badges] << badge_data unless session[:newly_earned_badges].any? { |b| b['id'] == badge.id }
      end

      Rails.logger.debug do
        "[BadgeNotifications] Stored badges in session: #{session[:newly_earned_badges].map do |b|
          b['name']
        end.join(', ')}"
      end
    rescue StandardError => e
      # セッション関連エラーをキャッチして本番環境での問題を防ぐ
      Rails.logger.error "[BadgeNotifications] Error storing badge notifications in session: #{e.message}"
      Rails.logger.error "[BadgeNotifications] Backtrace: #{e.backtrace.first(3).join("\n")}" if e.backtrace
      # エラーがあってもアプリケーションの動作を続行
    end
  end

  # 保存された通知を取得してクリア（デバッグログ付き）
  def getandclear_badge_notifications
    return [] if session[:newly_earned_badges].blank?

    notifications = session[:newly_earned_badges].dup
    # セッションをクリア
    session.delete(:newly_earned_badges)

    # デバッグログ
    Rails.logger.info "Badge notifications cleared from session: #{notifications.pluck('name').join(', ')}" if notifications.any?
    notifications
  rescue StandardError => e
    # セッション関連エラーをキャッチして本番環境での問題を防ぐ
    Rails.logger.error "[BadgeNotifications] Error accessing session for badge notifications: #{e.message}"
    Rails.logger.error "[BadgeNotifications] Backtrace: #{e.backtrace.first(3).join("\n")}" if e.backtrace
    []
  end

  # 通知フラッシュメッセージを設定（デバッグログ付き）
  def badge_notification_flash
    # Turboリクエストではフラッシュを使わない
    return if request.format.turbo_stream?

    begin
      notifications = getandclear_badge_notifications
      return if notifications.blank?

      flash[:success] = if notifications.size == 1
                          "🎉おめでとうございます! バッジ「#{notifications.first['name']}」を獲得しました！"
                        else
                          "🎉おめでとうございます! #{notifications.size}個のバッジを獲得しました！"
                        end

      Rails.logger.debug do
        "[BadgeNotifications] Flash set for badges: #{notifications.map do |n|
          n['name']
        end.join(', ')}"
      end
    rescue StandardError => e
      # 本番環境でのセッション関連エラーを防ぐため、エラーをログに記録するのみ
      Rails.logger.error "[BadgeNotifications] Error setting badge notification flash: #{e.message}"
      Rails.logger.error "[BadgeNotifications] Backtrace: #{e.backtrace.first(3).join("\n")}" if e.backtrace
      # エラーがあってもアプリケーションの動作を続行
    end
  end
end
