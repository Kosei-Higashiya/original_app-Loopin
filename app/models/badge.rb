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

  # condition_typeの日本語名を返す
  def condition_type_name
    CONDITION_TYPES[condition_type] || condition_type
  end

  # Check if badge conditions are met using precomputed stats
  # @param user_stats [Hash] Hash containing :consecutive_days, :total_habits, :total_records, :completion_rate
  # @return [Boolean] true if badge conditions are met
  # @note Missing hash keys are treated as 0 values via .to_i/.to_f for defensive programming
  def earned_by_stats?(user_stats)
    return false unless user_stats.is_a?(Hash)

    case condition_type
    when 'consecutive_days'
      user_stats[:consecutive_days].to_i >= condition_value
    when 'total_habits'
      user_stats[:total_habits].to_i >= condition_value
    when 'total_records'
      user_stats[:total_records].to_i >= condition_value
    when 'completion_rate'
      user_stats[:completion_rate].to_f >= condition_value
    else
      false
    end
  end

  # ユーザーがこのバッジの条件を満たしているかチェック
  def earned_by?(user)
    return false unless user

    begin
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
    rescue StandardError => e
      Rails.logger.error "Error checking badge '#{name}' for user #{user.id}: #{e.message}"
      false
    end
  end
end
