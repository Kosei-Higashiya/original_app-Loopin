class Habit < ApplicationRecord
  belongs_to :user
  has_many :habit_records, dependent: :destroy
  has_many :posts, dependent: :destroy

  validates :title, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: 1000 }

  scope :recent, -> { order(created_at: :desc) }
end
