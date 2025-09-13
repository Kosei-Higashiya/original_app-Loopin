# Badge checking concern to isolate and optimize badge logic
module BadgeChecker
  extend ActiveSupport::Concern

  # 高速バッジチェックメソッド
  def perform_badge_check_for_user(user)
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    results = { newly_earned: [], errors: [], stats: {} }

    begin
      Rails.logger.info "[BadgeCheck] Starting for user #{user.id} at #{Time.current}"

      # Step 1: Get user's current badge IDs (fast query)
      earned_badge_ids = user.user_badges.pluck(:badge_id)
      Rails.logger.debug "[BadgeCheck] User has #{earned_badge_ids.count} existing badges"

      # Step 2: Get all active badges not yet earned (single query)
      available_badges = Badge.active.where.not(id: earned_badge_ids).limit(20) # Limit to prevent timeout
      Rails.logger.debug "[BadgeCheck] Checking #{available_badges.count} available badges"

      # Step 3: Pre-calculate user stats to avoid repeated queries
      user_stats = calculate_user_stats(user)
      results[:stats] = user_stats

      # Step 4: Check each badge quickly
      available_badges.each do |badge|
        check_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        begin
          if badge_earned_by_stats?(badge, user_stats)
            # Create the badge record
            user_badge = UserBadge.create!(
              user: user,
              badge: badge,
              earned_at: Time.current
            )
            results[:newly_earned] << badge
            Rails.logger.info "[BadgeCheck] Badge '#{badge.name}' awarded to user #{user.id}"
          end
        rescue => e
          error_msg = "Failed to award badge '#{badge.name}': #{e.message}"
          results[:errors] << error_msg
          Rails.logger.error "[BadgeCheck] #{error_msg}"
        end

        check_end = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        check_duration = ((check_end - check_start) * 1000).round(2)

        # If a single badge check takes too long, log warning
        if check_duration > 100 # 100ms
          Rails.logger.warn "[BadgeCheck] Badge '#{badge.name}' check took #{check_duration}ms"
        end
      end

    rescue => e
      error_msg = "Badge check failed: #{e.message}"
      results[:errors] << error_msg
      Rails.logger.error "[BadgeCheck] #{error_msg}"
      Rails.logger.error "[BadgeCheck] Backtrace: #{e.backtrace.first(3).join("\n")}"
    ensure
      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      total_duration = ((end_time - start_time) * 1000).round(2)
      Rails.logger.info "[BadgeCheck] Completed for user #{user.id} in #{total_duration}ms. Awarded: #{results[:newly_earned].count}, Errors: #{results[:errors].count}"
    end

    results
  end

  private

  # Pre-calculate all user stats to avoid multiple DB queries
  def calculate_user_stats(user)
    # Get basic stats
    total_habits = user.habits.count

    # Calculate completion rate using the correct logic
    # The app deletes records for incomplete habits, so we need to calculate
    # based on possible vs actual records
    thirty_days_ago = 30.days.ago.to_date
    today = Date.current
    total_possible_records = if total_habits > 0
      (today - thirty_days_ago + 1).to_i * total_habits
    else
      0
    end

    completed_records = user.habit_records.where(
      recorded_at: thirty_days_ago..today,
      completed: true
    ).count

    completion_rate = if total_possible_records > 0
      (completed_records.to_f / total_possible_records * 100).round(1)
    else
      0.0
    end

    consecutive_days = calculate_max_consecutive_days(user)

    stats = {
      total_habits: total_habits,
      total_records: user.habit_records.count,
      completed_records: completed_records,
      consecutive_days: consecutive_days,
      completion_rate: completion_rate
    }

    Rails.logger.info "[BadgeCheck] Calculated stats for user #{user.id}: #{stats}"
    stats
  end

  # Fast badge condition checking using pre-calculated stats
  def badge_earned_by_stats?(badge, user_stats)
    case badge.condition_type
    when 'consecutive_days'
      result = user_stats[:consecutive_days] >= badge.condition_value
      Rails.logger.debug "[BadgeCheck] Badge '#{badge.name}' consecutive_days check: #{user_stats[:consecutive_days]} >= #{badge.condition_value} = #{result}"
      result
    when 'total_habits'
      result = user_stats[:total_habits] >= badge.condition_value
      Rails.logger.debug "[BadgeCheck] Badge '#{badge.name}' total_habits check: #{user_stats[:total_habits]} >= #{badge.condition_value} = #{result}"
      result
    when 'total_records'
      result = user_stats[:total_records] >= badge.condition_value
      Rails.logger.debug "[BadgeCheck] Badge '#{badge.name}' total_records check: #{user_stats[:total_records]} >= #{badge.condition_value} = #{result}"
      result
    when 'completion_rate'
      result = user_stats[:completion_rate] >= badge.condition_value
      Rails.logger.debug "[BadgeCheck] Badge '#{badge.name}' completion_rate check: #{user_stats[:completion_rate]} >= #{badge.condition_value} = #{result}"
      result
    else
      Rails.logger.warn "[BadgeCheck] Unknown badge condition type: #{badge.condition_type} for badge '#{badge.name}'"
      false
    end
  end

  # Optimized consecutive days calculation
  def calculate_max_consecutive_days(user)
    # Since recorded_at is already a date field, we can use DISTINCT directly
    # Also ensure we only get completed records
    records = user.habit_records.where(completed: true)
                  .select('DISTINCT recorded_at')
                  .order('recorded_at')
                  .pluck('recorded_at')

    Rails.logger.debug "[BadgeCheck] Found #{records.count} unique completed dates for user #{user.id}: #{records.join(', ')}"
    return 0 if records.empty?

    max_streak = 1
    current_streak = 1

    records.each_cons(2) do |prev_date, curr_date|
      # Date型同士の減算は日数を返すため、1日差かをチェック
      days_diff = (curr_date - prev_date).to_i
      Rails.logger.debug "[BadgeCheck] Comparing #{prev_date} to #{curr_date}: diff = #{days_diff} days"
      
      if days_diff == 1
        current_streak += 1
        max_streak = [max_streak, current_streak].max
        Rails.logger.debug "[BadgeCheck] Consecutive! Current streak: #{current_streak}, max: #{max_streak}"
      else
        current_streak = 1
        Rails.logger.debug "[BadgeCheck] Streak broken, reset to 1"
      end
    end

    Rails.logger.info "[BadgeCheck] Final max consecutive days for user #{user.id}: #{max_streak}"
    max_streak
  rescue => e
    Rails.logger.error "[BadgeCheck] Error calculating consecutive days: #{e.message}"
    Rails.logger.error "[BadgeCheck] Backtrace: #{e.backtrace.first(3).join("\n")}"
    0
  end
end
