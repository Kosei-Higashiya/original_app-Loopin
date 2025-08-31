class HabitRecord < ApplicationRecord
  belongs_to :user
  
  validates :title, presence: true, length: { maximum: 255 }
  validates :content, length: { maximum: 1000 }
  
  scope :recent, -> { order(created_at: :desc) }
  scope :public_records, -> { where(is_public: true) }
end