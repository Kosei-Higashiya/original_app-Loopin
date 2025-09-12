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
    {
      total_habits: user.habits.count,
      total_records: user.habit_records.count,
      completed_records: user.habit_records.where(completed: true).count,
      consecutive_days: calculate_max_consecutive_days(user),
      completion_rate: 0 # Will be calculated below
    }.tap do |stats|
      # Calculate completion rate
      stats[:completion_rate] = if stats[:total_records] > 0
        (stats[:completed_records].to_f / stats[:total_records] * 100).round(1)
      else
        0.0
      end
    end
  end
  
  # Fast badge condition checking using pre-calculated stats
  def badge_earned_by_stats?(badge, user_stats)
    case badge.condition_type
    when 'consecutive_days'
      user_stats[:consecutive_days] >= badge.condition_value
    when 'total_habits'
      user_stats[:total_habits] >= badge.condition_value
    when 'total_records'
      user_stats[:total_records] >= badge.condition_value
    when 'completion_rate'
      user_stats[:completion_rate] >= badge.condition_value
    else
      false
    end
  end
  
  # Optimized consecutive days calculation
  def calculate_max_consecutive_days(user)
    # Use raw SQL for better performance on large datasets
    records = user.habit_records.where(completed: true)
                  .select('DATE(recorded_at) as record_date')
                  .group('DATE(recorded_at)')
                  .order('record_date')
                  .pluck('record_date')
    
    return 0 if records.empty?
    
    max_streak = 1
    current_streak = 1
    
    records.each_cons(2) do |prev_date, curr_date|
      if (Date.parse(curr_date.to_s) - Date.parse(prev_date.to_s)).to_i == 1
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
end