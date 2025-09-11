class UserBadge < ApplicationRecord
  belongs_to :user
  belongs_to :badge

  validates :earned_at, presence: true
  validates :user_id, uniqueness: { scope: :badge_id, message: "has already earned this badge" }

  scope :recent, -> { order(earned_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }

  def self.award_badge(user, badge)
    return false if user.has_badge?(badge)
    return false unless badge.earned_by?(user)

    create!(
      user: user,
      badge: badge,
      earned_at: Time.current
    )
  end
end