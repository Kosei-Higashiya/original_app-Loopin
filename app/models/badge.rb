class Badge < ApplicationRecord
  has_many :user_badges, dependent: :destroy
  has_many :users, through: :user_badges

  validates :name, presence: true, uniqueness: true, length: { maximum: 255 }
  validates :description, length: { maximum: 1000 }
  validates :condition_type, presence: true
  validates :condition_value, presence: true, numericality: { greater_than: 0 }
  validates :icon, length: { maximum: 255 }

  scope :active, -> { where(active: true) }

  # バッジの条件タイプ定数
  CONDITION_TYPES = {
    'consecutive_days' => '連続日数',
    'total_habits' => '習慣総数', 
    'total_records' => '記録総数',
    'completion_rate' => '完了率'
  }.freeze

  def condition_type_name
    CONDITION_TYPES[condition_type] || condition_type
  end

  # ユーザーがこのバッジの条件を満たしているかチェック
  def earned_by?(user)
    case condition_type
    when 'consecutive_days'
      user.max_consecutive_days >= condition_value
    when 'total_habits'
      user.habits.count >= condition_value
    when 'total_records'
      user.habit_records.count >= condition_value
    when 'completion_rate'
      user.overall_completion_rate >= condition_value
    else
      false
    end
  end
end