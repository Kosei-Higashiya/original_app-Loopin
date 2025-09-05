class Post < ApplicationRecord
  belongs_to :user
  belongs_to :habit

  validates :content, presence: true, length: { maximum: 1000 }
  validates :image, length: { maximum: 255 }

  scope :recent, -> { order(created_at: :desc) }
  scope :with_associations, -> { includes(:user, :habit) }
end