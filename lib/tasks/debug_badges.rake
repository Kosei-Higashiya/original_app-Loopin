namespace :badges do
  desc "Debug badge system and verify 7-day consecutive badge"
  task debug: :environment do
    puts "=== Badge System Debugging ==="
    
    # Check if 7-day badge exists
    seven_day_badge = Badge.find_by(name: "1週間継続")
    
    if seven_day_badge
      puts "✅ 7-day badge exists:"
      puts "   Name: #{seven_day_badge.name}"
      puts "   Condition: #{seven_day_badge.condition_type} >= #{seven_day_badge.condition_value}"
      puts "   Active: #{seven_day_badge.active?}"
    else
      puts "❌ 7-day badge does not exist! Creating it..."
      seven_day_badge = Badge.create!(
        name: "1週間継続",
        description: "7日間連続で記録しました",
        condition_type: "consecutive_days",
        condition_value: 7,
        icon: "💪",
        active: true
      )
      puts "✅ Created 7-day badge with ID: #{seven_day_badge.id}"
    end
    
    # Test with first user
    user = User.first
    if user.nil?
      puts "❌ No users found in database"
      return
    end
    
    puts "\n=== User Statistics for #{user.display_name} (ID: #{user.id}) ==="
    
    # Get user's consecutive days using both methods
    user_consecutive = user.max_consecutive_days
    puts "User#max_consecutive_days: #{user_consecutive}"
    
    # Get badge checker consecutive days
    include BadgeChecker
    stats = calculate_user_stats(user)
    checker_consecutive = stats[:consecutive_days]
    puts "BadgeChecker#calculate_max_consecutive_days: #{checker_consecutive}"
    
    # Check if values match
    if user_consecutive == checker_consecutive
      puts "✅ Both methods return the same value"
    else
      puts "❌ Methods return different values! This is the bug."
    end
    
    # Test badge condition
    puts "\n=== Badge Condition Test ==="
    puts "Should earn 7-day badge (user method): #{user_consecutive >= 7}"
    puts "Should earn 7-day badge (checker method): #{checker_consecutive >= 7}"
    
    # Check if user already has the badge
    has_badge = user.user_badges.exists?(badge: seven_day_badge)
    puts "User already has 7-day badge: #{has_badge}"
    
    # Manual badge check using Badge#earned_by?
    earns_badge = seven_day_badge.earned_by?(user)
    puts "Badge#earned_by? result: #{earns_badge}"
    
    # Show user's recent habit records
    puts "\n=== Recent Habit Records (last 10 days) ==="
    recent_records = user.habit_records
                        .where(recorded_at: 10.days.ago..Date.current, completed: true)
                        .order(:recorded_at)
                        .pluck(:recorded_at)
                        .uniq
    
    if recent_records.any?
      puts "Completed dates: #{recent_records.map(&:strftime).join(', ')}"
      
      # Manual consecutive calculation
      if recent_records.length >= 2
        streaks = []
        current_streak = 1
        
        recent_records.each_cons(2) do |prev_date, curr_date|
          if (curr_date - prev_date).to_i == 1
            current_streak += 1
          else
            streaks << current_streak
            current_streak = 1
          end
        end
        streaks << current_streak
        
        puts "Manual streak calculation: longest streak = #{streaks.max}"
      else
        puts "Manual streak calculation: #{recent_records.length} day(s)"
      end
    else
      puts "No completed records in the last 10 days"
    end
    
    puts "\n=== Badge Check Test ==="
    begin
      # Try manual badge check
      newly_earned = user.check_and_award_badges
      if newly_earned.any?
        puts "✅ Manual check awarded #{newly_earned.count} badges: #{newly_earned.map(&:name).join(', ')}"
      else
        puts "Manual check awarded no new badges"
      end
    rescue => e
      puts "❌ Error during manual badge check: #{e.message}"
    end
    
    begin
      # Try badge checker method
      include BadgeChecker
      results = perform_badge_check_for_user(user)
      if results[:newly_earned].any?
        puts "✅ Badge checker awarded #{results[:newly_earned].count} badges: #{results[:newly_earned].map(&:name).join(', ')}"
      else
        puts "Badge checker awarded no new badges"
      end
      
      if results[:errors].any?
        puts "❌ Badge checker errors: #{results[:errors].join(', ')}"
      end
    rescue => e
      puts "❌ Error during badge checker: #{e.message}"
    end
  end
  
  desc "Force create all missing badges from seeds"
  task ensure_seeds: :environment do
    puts "=== Ensuring all badges from seeds exist ==="
    
    badges_data = [
      {
        name: "テスト用バッジ",
        description: "バッジ機能をテストするためのバッジです。誰でも獲得できます。",
        condition_type: "total_habits",
        condition_value: 0,
        icon: "🎉"
      },
      {
        name: "初回習慣",
        description: "最初の習慣を作成しました",
        condition_type: "total_habits",
        condition_value: 1,
        icon: "🎯"
      },
      {
        name: "習慣コレクター",
        description: "3つの習慣を作成しました",
        condition_type: "total_habits",
        condition_value: 3,
        icon: "📝"
      },
      {
        name: "習慣マスター",
        description: "5つの習慣を作成しました",
        condition_type: "total_habits",
        condition_value: 5,
        icon: "⭐"
      },
      {
        name: "3日間継続",
        description: "3日間連続で記録しました",
        condition_type: "consecutive_days",
        condition_value: 3,
        icon: "🔥"
      },
      {
        name: "1週間継続",
        description: "7日間連続で記録しました",
        condition_type: "consecutive_days",
        condition_value: 7,
        icon: "💪"
      },
      {
        name: "1ヶ月継続",
        description: "30日間連続で記録しました",
        condition_type: "consecutive_days",
        condition_value: 30,
        icon: "🏆"
      },
      {
        name: "記録スタート",
        description: "10回記録しました",
        condition_type: "total_records",
        condition_value: 10,
        icon: "📊"
      },
      {
        name: "記録王",
        description: "100回記録しました",
        condition_type: "total_records",
        condition_value: 100,
        icon: "👑"
      },
      {
        name: "完璧主義者",
        description: "完了率90%以上を達成しました",
        condition_type: "completion_rate",
        condition_value: 90,
        icon: "✨"
      }
    ]
    
    created_count = 0
    updated_count = 0
    
    badges_data.each do |badge_data|
      badge = Badge.find_by(name: badge_data[:name])
      
      if badge
        # Update existing badge to ensure it has correct values
        old_values = badge.attributes.slice('description', 'condition_type', 'condition_value', 'icon', 'active')
        badge.update!(
          description: badge_data[:description],
          condition_type: badge_data[:condition_type], 
          condition_value: badge_data[:condition_value],
          icon: badge_data[:icon],
          active: true
        )
        new_values = badge.reload.attributes.slice('description', 'condition_type', 'condition_value', 'icon', 'active')
        
        if old_values != new_values
          puts "📝 Updated badge '#{badge.name}'"
          updated_count += 1
        end
      else
        # Create new badge
        badge = Badge.create!(badge_data.merge(active: true))
        puts "✅ Created badge '#{badge.name}'"
        created_count += 1
      end
    end
    
    puts "\n=== Results ==="
    puts "Created: #{created_count} badges"
    puts "Updated: #{updated_count} badges"
    puts "Total badges: #{Badge.count}"
  end
end