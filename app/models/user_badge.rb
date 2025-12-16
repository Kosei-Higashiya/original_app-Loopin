class UserBadge < ApplicationRecord
  belongs_to :user
  belongs_to :badge

  validates :earned_at, presence: true
  validates :user_id, uniqueness: { scope: :badge_id, message: 'has already earned this badge' }

  scope :recent, -> { order(earned_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }

  # バッジをユーザーに付与するメソッド
  # @param user [User] バッジを付与するユーザー
  # @param badge [Badge] 付与するバッジ
  # @param user_stats [Hash, nil] オプション: 事前計算されたユーザー統計
  # @return [UserBadge, nil] 作成されたUserBadgeインスタンス、または付与されなかった場合はnil
  def self.award_badge(user, badge, user_stats: nil)
    # すでにバッジを持っていたら付与しない
    return nil if user.badge?(badge)

    # バッジの獲得条件を満たしているかチェック
    earned = if user_stats
               badge.earned_by_stats?(user_stats)
             else
               badge.earned_by?(user)
             end

    return nil unless earned

    # バッジを付与
    begin
      create!(
        user: user,
        badge: badge,
        earned_at: Time.current
      )
    rescue ActiveRecord::RecordNotUnique => e
      # 同時実行でバッジが既に作成された場合
      Rails.logger.warn "[UserBadge] Badge '#{badge.name}' already awarded to user #{user.id}: #{e.message}"
      nil
    end
  end
end
