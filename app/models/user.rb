class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :habits, dependent: :destroy
  has_many :habit_records, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :user_badges, dependent: :destroy
  has_many :badges, through: :user_badges

  # 名前が空の場合、ゲストを表示名として返す
  def display_name
    name.present? ? name : "ゲスト"
  end

  # バッジ関連メソッド
  def has_badge?(badge)
    user_badges.exists?(badge: badge)
  end

  def earned_badges
    badges.joins(:user_badges).order('user_badges.earned_at DESC')
  end

  # 統計メソッド（バッジ条件チェック用）
  def max_consecutive_days
    # 最大連続日数を計算
    records = habit_records.where(completed: true).order(:recorded_at)
    return 0 if records.empty?

    max_streak = 1
    current_streak = 1
    
    records.each_cons(2) do |prev, curr|
      if (curr.recorded_at - prev.recorded_at).to_i == 1
        current_streak += 1
        max_streak = [max_streak, current_streak].max
      else
        current_streak = 1
      end
    end
    
    max_streak
  end

  def overall_completion_rate
    total_records = habit_records.count
    return 0 if total_records.zero?
    
    completed_records = habit_records.where(completed: true).count
    (completed_records.to_f / total_records * 100).round(1)
  end

  # 新しいバッジを自動的にチェックして付与
  def check_and_award_badges
    Badge.active.each do |badge|
      next if has_badge?(badge)
      
      UserBadge.award_badge(self, badge) if badge.earned_by?(self)
    end
  end
end
