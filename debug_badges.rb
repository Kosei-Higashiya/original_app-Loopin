#!/usr/bin/env ruby
require_relative 'config/environment'

# Create test data
puts "Creating test data..."

# Clean up existing data
User.destroy_all
Habit.destroy_all
HabitRecord.destroy_all
Badge.destroy_all
UserBadge.destroy_all

# Create user
user = User.create!(
  email: 'test@example.com', 
  password: 'password123',
  name: 'Test User'
)
puts "Created user: #{user.email}"

# Create habit
habit = user.habits.create!(
  title: 'Test Habit',
  description: 'A test habit'
)
puts "Created habit: #{habit.title}"

# Create badges
badges = [
  Badge.create!(
    name: '3日連続',
    description: '3日連続で習慣を達成',
    icon: '🔥',
    condition_type: 'consecutive_days',
    condition_value: 3,
    active: true
  ),
  Badge.create!(
    name: '7日連続',
    description: '7日連続で習慣を達成',
    icon: '⭐',
    condition_type: 'consecutive_days',
    condition_value: 7,
    active: true
  )
]

puts "Created badges: #{badges.map(&:name).join(', ')}"

# Test scenario 1: Create 3 consecutive days of records
puts "\n=== Test Scenario 1: 3 consecutive days ==="
dates = [Date.current - 2, Date.current - 1, Date.current]
dates.each do |date|
  record = habit.habit_records.create!(
    user: user,
    recorded_at: date,
    completed: true
  )
  puts "Created record for #{date}: #{record.persisted?}"
end

# Check consecutive days calculation
puts "\nUser max_consecutive_days: #{user.max_consecutive_days}"
puts "BadgeChecker calculation:"
stats = user.send(:calculate_user_stats, user)
puts "Stats: #{stats}"

# Check badge awarding
puts "\nRunning badge check..."
results = user.perform_badge_check_for_user(user)
puts "Badge check results:"
puts "- Newly earned: #{results[:newly_earned].map(&:name).join(', ')}"
puts "- Errors: #{results[:errors]}"

puts "\nUser badges after check:"
user.reload
puts "User has badges: #{user.badges.pluck(:name).join(', ')}"

# Test scenario 2: Delete middle record to break streak
puts "\n=== Test Scenario 2: Break streak by deleting middle record ==="
middle_record = habit.habit_records.find_by(recorded_at: Date.current - 1)
if middle_record
  puts "Deleting record for #{middle_record.recorded_at}"
  middle_record.destroy!
  
  # Check consecutive days after deletion
  user.reload
  puts "User max_consecutive_days after deletion: #{user.max_consecutive_days}"
  
  # Run badge check again
  results = user.perform_badge_check_for_user(user)
  puts "Badge check results after deletion:"
  puts "- Newly earned: #{results[:newly_earned].map(&:name).join(', ')}"
  puts "- Errors: #{results[:errors]}"
end

puts "\nFinal user badges:"
puts "User has badges: #{user.badges.pluck(:name).join(', ')}"