# バッジチェックサービスクラス
class BadgeService
  # ユーザーのバッジ獲得条件をチェックし、条件を満たすバッジを付与する
  def self.check_and_award_badges_for_user(user)
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    results = { newly_earned: [], errors: [], stats: {} }

    begin
      Rails.logger.info "[BadgeCheck] Starting for user #{user.id} at #{Time.current}"

      # Step 1: ユーザーが既に獲得しているバッジIDを取得
      earned_badge_ids = user.user_badges.pluck(:badge_id)
      Rails.logger.debug { "[BadgeCheck] User has #{earned_badge_ids.count} existing badges" }

      # Step 2: 獲得していないすべてのアクティブなバッジを取得
      available_badges = Badge.active.where.not(id: earned_badge_ids).limit(20)
      Rails.logger.debug { "[BadgeCheck] Checking #{available_badges.count} available badges" }

      # Step 3: ユーザーの統計情報を事前計算
      user_stats = calculate_user_stats(user)
      results[:stats] = user_stats

      # Step 4: 各バッジをチェック
      available_badges.each do |badge|
        check_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        begin
          if badge.earned_by_stats?(user_stats)
            # award_badge メソッドを使用してバッジを授与する
            awarded = UserBadge.award_badge(user, badge, user_stats: user_stats)
            if awarded
              results[:newly_earned] << badge
              Rails.logger.info "[BadgeCheck] Badge '#{badge.name}' awarded to user #{user.id}"
            else
              Rails.logger.debug "[BadgeCheck] Badge '#{badge.name}' was not awarded (already exists or concurrent creation)"
            end
          end
        rescue StandardError => e
          error_msg = "Failed to award badge '#{badge.name}': #{e.message}"
          results[:errors] << error_msg
          Rails.logger.error "[BadgeCheck] #{error_msg}"
        end

        check_end = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        check_duration = ((check_end - check_start) * 1000).round(2)
        Rails.logger.warn "[BadgeCheck] Badge '#{badge.name}' check took #{check_duration}ms" if check_duration > 100
      end
    rescue StandardError => e
      error_msg = "Badge check failed: #{e.message}"
      results[:errors] << error_msg
      Rails.logger.error "[BadgeCheck] #{error_msg}"
      Rails.logger.error "[BadgeCheck] Backtrace: #{e.backtrace.first(3).join("\n")}"
    ensure
      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      total_duration = ((end_time - start_time) * 1000).round(2)
      Rails.logger.info "[BadgeCheck] Completed for user #{user.id} in #{total_duration}ms. " \
                        "Awarded: #{results[:newly_earned].count}, Errors: #{results[:errors].count}"
    end

    results
  end

  # ユーザーの統計情報を計算する
  # バッジ獲得条件の判定に使用する統計データをまとめて計算することで、
  # 各バッジ条件チェック時の個別クエリを削減する
  def self.calculate_user_stats(user)
    total_habits = user.habits.count
    thirty_days_ago = 30.days.ago.to_date
    today = Date.current

    total_possible_records = total_habits.positive? ? (today - thirty_days_ago + 1).to_i * total_habits : 0
    completed_records = user.habit_records.where(recorded_at: thirty_days_ago..today, completed: true).count
    completion_rate = total_possible_records.positive? ? (completed_records.to_f / total_possible_records * 100).round(1) : 0.0

    {
      total_habits: total_habits,
      total_records: user.habit_records.count,
      completed_records: completed_records,
      consecutive_days: calculate_max_consecutive_days(user),
      completion_rate: completion_rate
    }
  end

  # ユーザーの最大連続日数を計算する
  # 完了した習慣記録の日付から、最も長い連続日数を計算する
  def self.calculate_max_consecutive_days(user)
    unique_dates = user.habit_records.where(completed: true)
                       .pluck(:recorded_at)
                       .uniq
                       .sort

    return 0 if unique_dates.empty?

    max_streak = 1
    current_streak = 1

    unique_dates.each_cons(2) do |prev_date, curr_date|
      if (curr_date - prev_date).to_i == 1
        current_streak += 1
        max_streak = [max_streak, current_streak].max
      else
        current_streak = 1
      end
    end

    max_streak
  end

  # ユーザーの全習慣の完了率を計算する
  # 過去30日間での記録可能数に対する完了記録数の割合を返す
  def self.calculate_completion_rate(user)
    total_habits = user.habits.count
    return 0.0 if total_habits.zero?

    thirty_days_ago = 30.days.ago.to_date
    today = Date.current
    total_possible_records = (today - thirty_days_ago + 1).to_i * total_habits

    completed_records = user.habit_records.where(
      recorded_at: thirty_days_ago..today,
      completed: true
    ).count

    return 0.0 if total_possible_records.zero?

    (completed_records.to_f / total_possible_records * 100).round(1)
  end

  private_class_method :calculate_user_stats, :calculate_max_consecutive_days, :calculate_completion_rate
end
