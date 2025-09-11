class Habit < ApplicationRecord
  belongs_to :user
  has_many :habit_records, dependent: :destroy
  has_many :posts, dependent: :destroy


  validates :title, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: 1000 }

  # Check for new badges after creating a habit
  after_create :check_user_badges

  scope :recent, -> { order(created_at: :desc) }

   # Ransack設定
  def self.ransackable_attributes(auth_object = nil)
    ["title", "description", "created_at", "id", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["posts", "user"]
  end

  private

  def check_user_badges
    user.check_and_award_badges
  end
end
