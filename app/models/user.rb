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

  # 獲得したバッジを取得
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

    records.pluck(:recorded_at).each_cons(2) do |prev_date, curr_date|
      if (curr_date - prev_date).to_i == 1
        current_streak += 1
        max_streak = [max_streak, current_streak].max
      else
        current_streak = 1
      end
    end

    max_streak
  end

  # 全習慣の完了率を計算
  def overall_completion_rate
    total_records = habit_records.count
    return 0 if total_records.zero?

    completed_records = habit_records.where(completed: true).count
    (completed_records.to_f / total_records * 100).round(1)
  end

  # 新しいバッジを自動的にチェックして付与
  def check_and_award_badges
    newly_earned_badges = []

    begin
      Rails.logger.debug "Starting badge check for user #{id}"

      # 効率的にバッジを取得（すでに獲得済みのバッジIDを除外）
      earned_badge_ids = user_badges.pluck(:badge_id)
      available_badges = Badge.active.where.not(id: earned_badge_ids)

      Rails.logger.debug "Found #{available_badges.count} available badges to check"

      available_badges.find_each do |badge|
        begin
          if badge.earned_by?(self)
            user_badge = UserBadge.create!(
              user: self,
              badge: badge,
              earned_at: Time.current
            )
            newly_earned_badges << badge
            Rails.logger.info "Badge '#{badge.name}' awarded to user #{id}"
          end
        rescue => e
          Rails.logger.error "Failed to award badge '#{badge.name}' to user #{id}: #{e.message}"
          # 個別のバッジエラーは全体の処理を停止しない
        end
      end

    rescue => e
      Rails.logger.error "Error during badge check for user #{id}: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.first(3).join("\n")}"
      # エラーが発生してもすでに付与されたバッジは返す
    end

    Rails.logger.debug "Badge check completed for user #{id}. Awarded #{newly_earned_badges.count} badges"
    newly_earned_badges
  end
end
