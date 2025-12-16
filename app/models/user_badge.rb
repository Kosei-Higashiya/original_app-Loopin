class UserBadge < ApplicationRecord
  belongs_to :user
  belongs_to :badge

  validates :earned_at, presence: true
  validates :user_id, uniqueness: { scope: :badge_id, message: 'has already earned this badge' }

  scope :recent, -> { order(earned_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }

  # バッジをユーザーに付与するメソッド
  def self.award_badge(user, badge, user_stats: nil)
    # すでにバッジを持っていたら付与しない (fast path)
    return nil if user.badge?(badge)

    # 獲得条件をチェック: user_statsが提供されていればそれを使用、なければearnerd_by?を使用
    earned = if user_stats
               badge.earned_by_stats?(user_stats)
             else
               badge.earned_by?(user)
             end

    # バッジの獲得条件を満たしていなければ付与しない
    return nil unless earned

    # 同時実行による重複を防ぐためRecordNotUniqueを捕捉
    begin
      create!(
        user: user,
        badge: badge,
        earned_at: Time.current
      )
    rescue ActiveRecord::RecordNotUnique => e
      Rails.logger.warn "[UserBadge] Badge '#{badge.name}' already awarded to user #{user.id} (concurrent creation prevented)"
      nil
    end
  end
end
