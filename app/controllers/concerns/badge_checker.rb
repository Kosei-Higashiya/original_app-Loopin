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

      # Step 2: Ensure essential badges exist (create if missing)
      ensure_essential_badges_exist
      
      # Step 3: Get all active badges not yet earned (single query)
      available_badges = Badge.active.where.not(id: earned_badge_ids).limit(20) # Limit to prevent timeout
      Rails.logger.debug "[BadgeCheck] Checking #{available_badges.count} available badges"

      # Step 4: Pre-calculate user stats to avoid repeated queries
      user_stats = calculate_user_stats(user)
      results[:stats] = user_stats

      # Step 5: Check each badge quickly
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

  # Ensure critical badges exist in the database
  def ensure_essential_badges_exist
    essential_badges = [
      {
        name: "1週間継続",
        description: "7日間連続で記録しました",
        condition_type: "consecutive_days",
        condition_value: 7,
        icon: "💪"
      },
      {
        name: "3日間継続",
        description: "3日間連続で記録しました",
        condition_type: "consecutive_days",
        condition_value: 3,
        icon: "🔥"
      }
    ]
    
    essential_badges.each do |badge_data|
      unless Badge.exists?(name: badge_data[:name])
        Badge.create!(badge_data.merge(active: true))
        Rails.logger.info "[BadgeCheck] Created missing essential badge: #{badge_data[:name]}"
      end
    end
  end

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
    
    {
      total_habits: total_habits,
      total_records: user.habit_records.count,
      completed_records: completed_records,
      consecutive_days: calculate_max_consecutive_days(user),
      completion_rate: completion_rate
    }
  end

  # Fast badge condition checking using pre-calculated stats
  def badge_earned_by_stats?(badge, user_stats)
    result = case badge.condition_type
    when 'consecutive_days'
      earned = user_stats[:consecutive_days] >= badge.condition_value
      
      # Special logging for consecutive days badges to help debug
      if badge.condition_value == 7 && badge.name.include?("週間")
        Rails.logger.info "[BadgeDebug] Checking 7-day badge '#{badge.name}': user has #{user_stats[:consecutive_days]} consecutive days, needs #{badge.condition_value}, earned: #{earned}"
      end
      
      earned
    when 'total_habits'
      user_stats[:total_habits] >= badge.condition_value
    when 'total_records'
      user_stats[:total_records] >= badge.condition_value
    when 'completion_rate'
      user_stats[:completion_rate] >= badge.condition_value
    else
      false
    end
    
    Rails.logger.debug "[BadgeCheck] Badge '#{badge.name}' (#{badge.condition_type}>=#{badge.condition_value}): #{result ? 'EARNED' : 'not earned'}"
    result
  end

  # Optimized consecutive days calculation
  def calculate_max_consecutive_days(user)
    # Since recorded_at is already a date field, we can use DISTINCT directly
    records = user.habit_records.where(completed: true)
                  .select('DISTINCT recorded_at')
                  .order('recorded_at')
                  .pluck('recorded_at')

    return 0 if records.empty?

    max_streak = 1
    current_streak = 1

    records.each_cons(2) do |prev_date, curr_date|
      # Date型同士の減算は日数を返すため、1日差かをチェック
      if (curr_date - prev_date).to_i == 1
        current_streak += 1
        max_streak = [max_streak, current_streak].max
      else
        current_streak = 1
      end
    end

    max_streak
  rescue => e
    Rails.logger.error "[BadgeCheck] Error calculating consecutive days: #{e.message}"
    0
  end

  # Debug method to help troubleshoot consecutive days badge issues
  def debug_consecutive_days_calculation(user)
    Rails.logger.info "[BadgeDebug] Starting consecutive days debug for user #{user.id}"
    
    # Get raw habit records
    records = user.habit_records.where(completed: true)
                  .select('DISTINCT recorded_at')
                  .order('recorded_at')
    
    dates_array = records.pluck('recorded_at')
    Rails.logger.info "[BadgeDebug] Found #{dates_array.count} unique completed dates: #{dates_array.map(&:to_s).join(', ')}"
    
    if dates_array.empty?
      Rails.logger.info "[BadgeDebug] No completed records found"
      return { consecutive_days: 0, debug_info: "No completed records" }
    end

    # Manual calculation with debug info
    max_streak = 1
    current_streak = 1
    streaks = []

    dates_array.each_cons(2) do |prev_date, curr_date|
      days_diff = (curr_date - prev_date).to_i
      Rails.logger.debug "[BadgeDebug] #{prev_date} -> #{curr_date}: #{days_diff} days apart"
      
      if days_diff == 1
        current_streak += 1
        max_streak = [max_streak, current_streak].max
      else
        streaks << current_streak
        current_streak = 1
      end
    end
    streaks << current_streak
    
    Rails.logger.info "[BadgeDebug] All streaks: #{streaks.join(', ')}, Max: #{max_streak}"
    
    # Compare with User model calculation
    user_result = user.max_consecutive_days
    Rails.logger.info "[BadgeDebug] User#max_consecutive_days: #{user_result}"
    Rails.logger.info "[BadgeDebug] BadgeChecker calculation: #{max_streak}"
    
    if user_result != max_streak
      Rails.logger.error "[BadgeDebug] MISMATCH! User model and BadgeChecker return different values"
    end
    
    # Check 7-day badge specifically
    seven_day_badge = Badge.find_by(name: "1週間継続")
    if seven_day_badge
      Rails.logger.info "[BadgeDebug] 7-day badge exists (ID: #{seven_day_badge.id}, active: #{seven_day_badge.active?})"
      Rails.logger.info "[BadgeDebug] User should earn 7-day badge: #{max_streak >= 7}"
      Rails.logger.info "[BadgeDebug] User already has 7-day badge: #{user.user_badges.exists?(badge: seven_day_badge)}"
    else
      Rails.logger.error "[BadgeDebug] 7-day badge '1週間継続' does not exist in database!"
    end
    
    {
      consecutive_days: max_streak,
      user_method_result: user_result,
      all_streaks: streaks,
      debug_info: "Found #{dates_array.count} unique dates, longest streak #{max_streak}",
      seven_day_badge_exists: !seven_day_badge.nil?,
      seven_day_badge_active: seven_day_badge&.active?
    }
  end
end
