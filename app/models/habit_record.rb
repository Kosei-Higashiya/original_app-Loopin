class HabitRecord < ApplicationRecord
  belongs_to :user
  belongs_to :habit

  validates :recorded_at, presence: true
  validates :notes, length: { maximum: 1000 }
  validates :completed, inclusion: { in: [true, false] }
  validates :user_id, uniqueness: { scope: [:habit_id, :recorded_at], 
                                   message: "can only have one record per habit per day" }

  # Ensure the habit belongs to the user
  validate :habit_must_belong_to_user

  scope :completed, -> { where(completed: true) }
  scope :incomplete, -> { where(completed: false) }
  scope :recent, -> { order(recorded_at: :desc) }
  scope :for_date, ->(date) { where(recorded_at: date) }
  scope :for_date_range, ->(start_date, end_date) { where(recorded_at: start_date..end_date) }

  private

  def habit_must_belong_to_user
    return unless habit && user
    
    unless habit.user_id == user.id
      errors.add(:habit, "must belong to the same user")
    end
  end
end