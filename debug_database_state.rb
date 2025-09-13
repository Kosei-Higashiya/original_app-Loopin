#!/usr/bin/env ruby
require_relative 'config/environment'

# Check current database state for consecutive days badges
puts "Checking database state for badge issues..."

puts "\n=== Badge Configuration ==="
badges = Badge.where(condition_type: 'consecutive_days').order(:condition_value)
if badges.any?
  badges.each do |badge|
    puts "Badge: '#{badge.name}' - #{badge.condition_value} days - Active: #{badge.active}"
  end
else
  puts "No consecutive days badges found in database!"
  puts "Creating default consecutive days badges..."
  
  # Create default badges if they don't exist
  [
    { name: '3日連続', value: 3 },
    { name: '7日連続', value: 7 },
    { name: '30日連続', value: 30 }
  ].each do |badge_config|
    Badge.create!(
      name: badge_config[:name],
      description: "#{badge_config[:value]}日連続で習慣を達成",
      condition_type: 'consecutive_days',
      condition_value: badge_config[:value],
      active: true
    )
    puts "Created badge: #{badge_config[:name]}"
  end
end

puts "\n=== Sample User Data Analysis ==="
# Check if there are any users with habit records
users_with_records = User.joins(:habit_records).distinct
puts "Users with habit records: #{users_with_records.count}"

if users_with_records.any?
  sample_user = users_with_records.first
  puts "\nAnalyzing sample user: #{sample_user.email}"
  
  # Get their habit records
  records = sample_user.habit_records.where(completed: true)
                      .select('DISTINCT recorded_at')
                      .order(:recorded_at)
                      .pluck(:recorded_at)
  
  puts "Completed record dates: #{records.join(', ')}"
  puts "Total unique completed dates: #{records.count}"
  
  if records.count >= 2
    # Check for consecutive days
    consecutive_days = sample_user.max_consecutive_days
    puts "Max consecutive days: #{consecutive_days}"
    
    # Check what badges they should have
    eligible_badges = Badge.where(condition_type: 'consecutive_days')
                          .where('condition_value <= ?', consecutive_days)
                          .order(:condition_value)
    
    puts "Badges they should have: #{eligible_badges.pluck(:name).join(', ')}"
    puts "Badges they actually have: #{sample_user.badges.pluck(:name).join(', ')}"
    
    # Run badge check
    puts "\nRunning badge check..."
    results = sample_user.perform_badge_check_for_user(sample_user)
    puts "Newly earned badges: #{results[:newly_earned].map(&:name).join(', ')}"
    puts "Errors: #{results[:errors]}"
    
    sample_user.reload
    puts "User badges after check: #{sample_user.badges.pluck(:name).join(', ')}"
  else
    puts "Not enough data to check consecutive days"
  end
else
  puts "No users with habit records found"
  puts "\nPossible issues:"
  puts "1. Users haven't created any habit records yet"
  puts "2. All habit records are marked as completed: false"
  puts "3. Database is empty"
end

# Check for timezone issues
puts "\n=== Timezone Information ==="
puts "Rails timezone: #{Rails.application.config.time_zone}"
puts "Current date: #{Date.current}"
puts "Current time: #{Time.current}"