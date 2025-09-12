namespace :badges do
  desc "Diagnose badge system performance and functionality"
  task diagnose: :environment do
    puts "=== Badge System Diagnostics ==="
    puts
    
    start_time = Time.current
    
    begin
      # Check basic badge setup
      total_badges = Badge.count
      active_badges = Badge.active.count
      puts "📊 Badge Statistics:"
      puts "  Total badges: #{total_badges}"
      puts "  Active badges: #{active_badges}"
      puts
      
      # Check if test badge exists
      test_badge = Badge.find_by(name: "テスト用バッジ")
      if test_badge
        puts "✅ Test badge exists: #{test_badge.name} (condition: #{test_badge.condition_type} >= #{test_badge.condition_value})"
      else
        puts "❌ Test badge missing - creating now..."
        test_badge = Badge.create!(
          name: "テスト用バッジ",
          description: "バッジ機能をテストするためのバッジです",
          condition_type: "total_habits",
          condition_value: 0,
          icon: "🎉",
          active: true
        )
        puts "✅ Test badge created: #{test_badge.name}"
      end
      puts
      
      # Check user badge system
      if User.exists?
        sample_user = User.first
        puts "🧪 Testing with sample user (ID: #{sample_user.id}):"
        
        # Test badge checking performance
        badge_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        newly_earned = sample_user.check_and_award_badges rescue []
        badge_end = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        badge_duration = ((badge_end - badge_start) * 1000).round(2)
        
        puts "  Badge check completed in #{badge_duration}ms"
        puts "  Newly earned badges: #{newly_earned.count}"
        puts "  Total user badges: #{sample_user.user_badges.count}"
        
        # Test user stats calculation
        stats_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        stats = {
          habits: sample_user.habits.count,
          records: sample_user.habit_records.count,
          completed_records: sample_user.habit_records.where(completed: true).count
        }
        stats_end = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        stats_duration = ((stats_end - stats_start) * 1000).round(2)
        
        puts "  Stats calculation in #{stats_duration}ms:"
        puts "    Habits: #{stats[:habits]}"
        puts "    Records: #{stats[:records]}"
        puts "    Completed: #{stats[:completed_records]}"
      else
        puts "⚠️  No users found - create a user to test badge functionality"
      end
      puts
      
      # Check database performance
      puts "🗄️  Database Performance:"
      
      # Check indexes
      indexes = ActiveRecord::Base.connection.execute(
        "SELECT schemaname, tablename, indexname FROM pg_indexes WHERE tablename IN ('badges', 'user_badges', 'users', 'habits', 'habit_records') ORDER BY tablename, indexname"
      ).to_a rescue []
      
      if indexes.any?
        puts "  Database indexes found: #{indexes.count}"
        %w[badges user_badges].each do |table|
          table_indexes = indexes.select { |idx| idx['tablename'] == table }
          puts "    #{table}: #{table_indexes.count} indexes"
        end
      else
        puts "  ⚠️  Could not check database indexes"
      end
      
      end_time = Time.current
      total_duration = ((end_time - start_time) * 1000).round(2)
      puts
      puts "✅ Diagnostics completed in #{total_duration}ms"
      
      if badge_duration && badge_duration > 1000
        puts
        puts "⚠️  WARNING: Badge checking is slow (#{badge_duration}ms)"
        puts "   Consider optimizing database queries or adding indexes"
      end
      
    rescue => e
      puts "❌ Error during diagnostics: #{e.message}"
      puts "   #{e.backtrace.first(3).join("\n   ")}"
    end
  end
  
  desc "Create test badge for immediate testing"
  task create_test_badge: :environment do
    test_badge = Badge.find_or_create_by(name: "テスト用バッジ") do |badge|
      badge.description = "バッジ機能をテストするためのバッジです。誰でも獲得できます。"
      badge.condition_type = "total_habits"
      badge.condition_value = 0
      badge.icon = "🎉"
      badge.active = true
    end
    
    puts "Test badge ready: #{test_badge.name} (ID: #{test_badge.id})"
  end
end