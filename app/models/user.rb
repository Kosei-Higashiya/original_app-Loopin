class User < ApplicationRecord
  include BadgeChecker
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
    # 各習慣ごとに最大連続日数を計算し、その中の最大値を返す
    Rails.logger.debug "[User#max_consecutive_days] Starting calculation for user #{id}"
    
    # Ensure we have fresh data by reloading habits association
    habits.reload
    return 0 if habits.empty?

    max_consecutive_across_habits = 0

    habits.each do |habit|
      # この習慣の完了記録を日付順で取得 - ensure fresh data
      habit_dates = habit.habit_records.where(completed: true)
                         .order(:recorded_at)
                         .pluck(:recorded_at)
      Rails.logger.info "[User#max_consecutive_days] Habit '#{habit.title}' (ID: #{habit.id}) has #{habit_dates.count} completed dates: #{habit_dates.join(', ')}"

      # Also log all records for debugging
      all_records = habit.habit_records.order(:recorded_at).pluck(:recorded_at, :completed)
      Rails.logger.info "[User#max_consecutive_days] All records for habit '#{habit.title}': #{all_records.map { |date, completed| "#{date}(#{completed ? 'T' : 'F'})" }.join(', ')}"

      next if habit_dates.empty?

      # この習慣の最大連続日数を計算
      habit_max_streak = calculate_consecutive_days_for_dates(habit_dates, habit.title)

      Rails.logger.info "[User#max_consecutive_days] Habit '#{habit.title}' max streak: #{habit_max_streak}, previous max: #{max_consecutive_across_habits}"

      # 全体の最大値を更新
      old_max = max_consecutive_across_habits
      max_consecutive_across_habits = [max_consecutive_across_habits, habit_max_streak].max
      Rails.logger.info "[User#max_consecutive_days] Updated max from #{old_max} to #{max_consecutive_across_habits}"
    end
     Rails.logger.warn "[User#max_consecutive_days] Final result for user #{id}: #{max_consecutive_across_habits} (max across all habits)"
     max_consecutive_across_habits

  rescue => e
    Rails.logger.error "[User#max_consecutive_days] Error: #{e.message}"
    Rails.logger.error "[User#max_consecutive_days] Backtrace: #{e.backtrace.first(3).join("\n")}"
    0
  end

  # 全習慣の完了率を計算
  def overall_completion_rate
    return 0 if habits.empty?

    # 全習慣の全日付での総記録可能数を計算
    # ユーザーが過去30日間で記録できた総日数 × 習慣数
    thirty_days_ago = 30.days.ago.to_date
    today = Date.current
    total_possible_records = (today - thirty_days_ago + 1).to_i * habits.count

    # 実際に記録された習慣数（すべて completed: true）
    completed_records = habit_records.where(
      recorded_at: thirty_days_ago..today,
      completed: true
    ).count

    return 0 if total_possible_records.zero?

    (completed_records.to_f / total_possible_records * 100).round(1)
  end

  # 新しいバッジを自動的にチェックして付与
   # This method is kept for backward compatibility but delegates to the optimized BadgeChecker
  def check_and_award_badges
    begin
      # Use the optimized badge checker
      results = perform_badge_check_for_user(self)

      Rails.logger.debug "Badge check completed for user #{id}. Awarded #{results[:newly_earned].count} badges via optimized checker"

      # Return newly earned badges for backward compatibility
      results[:newly_earned] || []

    rescue => e
      Rails.logger.error "Error during optimized badge check for user #{id}: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.first(3).join("\n")}"

      # Return empty array on error
      []
    end
  end

  private

  # 日付配列から最大連続日数を計算するヘルパーメソッド
  def calculate_consecutive_days_for_dates(dates, habit_name = "unknown")
    return 0 if dates.empty?
    return 1 if dates.length == 1

    max_streak = 1
    current_streak = 1

    dates.each_cons(2) do |prev_date, curr_date|
      # 隣り合う日付を比較して「1日差」なら連続、それ以外はリセット
      days_diff = (curr_date - prev_date).to_i
      Rails.logger.debug "[User#calculate_consecutive_days_for_dates] Habit '#{habit_name}': Comparing #{prev_date} to #{curr_date}: diff = #{days_diff} days"

      if days_diff == 1
        current_streak += 1
        max_streak = [max_streak, current_streak].max
        Rails.logger.debug "[User#calculate_consecutive_days_for_dates] Habit '#{habit_name}': Consecutive! Current streak: #{current_streak}, max: #{max_streak}"
      else
        current_streak = 1
        Rails.logger.debug "[User#calculate_consecutive_days_for_dates] Habit '#{habit_name}': Streak broken, reset to 1"
      end
    end

    Rails.logger.debug "[User#calculate_consecutive_days_for_dates] Habit '#{habit_name}': Final max streak: #{max_streak}"
    max_streak
  end
end
