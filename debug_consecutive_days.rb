#!/usr/bin/env ruby
require_relative 'config/environment'

# Test various consecutive days scenarios
puts "Testing consecutive days edge cases..."

# Clean up existing data
User.destroy_all
Habit.destroy_all
HabitRecord.destroy_all
Badge.destroy_all
UserBadge.destroy_all

# Create user and habit
user = User.create!(email: 'test@example.com', password: 'password123', name: 'Test User')
habit = user.habits.create!(title: 'Test Habit', description: 'A test habit')

# Create badges
badges = [
  Badge.create!(name: '3日連続', condition_type: 'consecutive_days', condition_value: 3, active: true),
  Badge.create!(name: '7日連続', condition_type: 'consecutive_days', condition_value: 7, active: true)
]

puts "Created user, habit, and badges"

# Test Case 1: 5 consecutive days
puts "\n=== Test Case 1: 5 consecutive days ==="
dates = [
  Date.current - 4,
  Date.current - 3,
  Date.current - 2,
  Date.current - 1,
  Date.current
]

dates.each do |date|
  habit.habit_records.create!(user: user, recorded_at: date, completed: true)
  puts "Created record for #{date}"
end

consecutive_days = user.max_consecutive_days
puts "Max consecutive days: #{consecutive_days}"

results = user.perform_badge_check_for_user(user)
puts "Badge check results: #{results[:newly_earned].map(&:name).join(', ')}"
puts "User badges: #{user.reload.badges.pluck(:name).join(', ')}"

# Test Case 2: Add 2 more days to make it 7
puts "\n=== Test Case 2: Extend to 7 consecutive days ==="
extra_dates = [Date.current + 1, Date.current + 2]
extra_dates.each do |date|
  habit.habit_records.create!(user: user, recorded_at: date, completed: true)
  puts "Created record for #{date}"
end

consecutive_days = user.max_consecutive_days
puts "Max consecutive days: #{consecutive_days}"

results = user.perform_badge_check_for_user(user)
puts "Badge check results: #{results[:newly_earned].map(&:name).join(', ')}"
puts "User badges: #{user.reload.badges.pluck(:name).join(', ')}"

# Test Case 3: Create a separate streak with a gap
puts "\n=== Test Case 3: Create separate streak with gap ==="
gap_dates = [Date.current + 5, Date.current + 6, Date.current + 7, Date.current + 8]
gap_dates.each do |date|
  habit.habit_records.create!(user: user, recorded_at: date, completed: true)
  puts "Created record for #{date}"
end

consecutive_days = user.max_consecutive_days
puts "Max consecutive days: #{consecutive_days}"

results = user.perform_badge_check_for_user(user)
puts "Badge check results: #{results[:newly_earned].map(&:name).join(', ')}"
puts "User badges: #{user.reload.badges.pluck(:name).join(', ')}"

# Test Case 4: Test with multiple habits same day
puts "\n=== Test Case 4: Multiple habits same day ==="
habit2 = user.habits.create!(title: 'Another Habit', description: 'Another test habit')
habit2.habit_records.create!(user: user, recorded_at: Date.current, completed: true)
habit2.habit_records.create!(user: user, recorded_at: Date.current + 1, completed: true)

consecutive_days = user.max_consecutive_days
puts "Max consecutive days: #{consecutive_days}"

results = user.perform_badge_check_for_user(user)
puts "Badge check results: #{results[:newly_earned].map(&:name).join(', ')}"
puts "User badges: #{user.reload.badges.pluck(:name).join(', ')}"

puts "\nAll habit records:"
user.habit_records.order(:recorded_at).each do |record|
  puts "  #{record.recorded_at}: #{record.habit.title} - #{record.completed? ? 'completed' : 'not completed'}"
end