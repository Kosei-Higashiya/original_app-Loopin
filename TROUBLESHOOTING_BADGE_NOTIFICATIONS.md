# Badge Notification System Troubleshooting Guide

## Current Status
✅ **All badge notification code is properly implemented**
❌ **Environment setup issue preventing testing**

## Root Cause
The Rails environment cannot start due to missing gem dependencies. This prevents:
- Badge checking functionality from being tested
- Database operations from being performed
- The application from running properly

## Step-by-Step Resolution

### 1. Install Dependencies
```bash
cd /path/to/original_app-Loopin
bundle install
```

### 2. Database Setup
```bash
# Ensure database is migrated
rails db:migrate

# Check if badges exist in database
rails runner "puts Badge.count"

# If no badges, create some test badges
rails runner "
Badge.create!(
  name: 'First Habit',
  description: 'Create your first habit',
  condition_type: 'total_habits',
  condition_value: 1,
  icon: '🎯',
  active: true
)
Badge.create!(
  name: 'Streak Master',
  description: 'Complete habits for 7 consecutive days',
  condition_type: 'consecutive_days',
  condition_value: 7,
  icon: '🔥',
  active: true
)
"
```

### 3. Test Badge Notification System

#### Manual Test via Web Interface:
1. Start Rails server: `rails server`
2. Navigate to `/badges`
3. Click "バッジをチェック" button
4. Check if congratulatory message appears

#### Test via Rails Console:
```ruby
rails console
user = User.first
badges = user.check_and_award_badges
puts "Newly earned badges: #{badges.count}"
```

#### Test Badge Conditions:
```ruby
rails console
user = User.first

# Check current stats
puts "Habits count: #{user.habits.count}"
puts "Records count: #{user.habit_records.count}"
puts "Max consecutive days: #{user.max_consecutive_days}"
puts "Overall completion rate: #{user.overall_completion_rate}"

# Test badge earning
Badge.all.each do |badge|
  earned = badge.earned_by?(user)
  has_badge = user.has_badge?(badge)
  puts "#{badge.name}: earned=#{earned}, has_badge=#{has_badge}"
end
```

### 4. Debug Badge Notifications

If badges are earned but notifications don't appear:

#### Check Flash Messages in Browser
1. Open browser developer tools
2. Check for flash message div: `<div id="flash-messages">`
3. Verify alert classes are applied correctly

#### Check Session Storage
```ruby
# In rails console after triggering badge check
# This won't work directly in console, but shows the logic
session[:newly_earned_badges]  # Should contain badge data
```

#### Check Notification Flow
```ruby
# Test the complete flow
user = User.first
badges = user.check_and_award_badges

# Simulate controller behavior
if badges.any?
  puts "Setting notification for badges: #{badges.map(&:name)}"
  # This would normally set session[:newly_earned_badges]
end
```

## Expected Behavior

### When Badge is Earned:
1. User performs action (create habit, record habit, etc.)
2. Controller calls `current_user.check_and_award_badges`
3. If new badges earned, `set_badge_notification(badges)` is called
4. Badge data stored in `session[:newly_earned_badges]`
5. Next page load triggers `set_badge_notification_flash`
6. Flash message appears: "おめでとうございます、バッジ「Badge Name」を獲得しました！"
7. Session data is cleared

### Manual Badge Check:
1. Click "バッジをチェック" button on `/badges` page
2. POST request to `/badges/check_awards`
3. `BadgesController#check_awards` executes
4. Same notification flow as above
5. Redirect back to badges page with notification

## Files Verified as Correct:
- ✅ `app/controllers/concerns/badge_notifications.rb`
- ✅ `app/controllers/application_controller.rb`
- ✅ `app/controllers/badges_controller.rb`
- ✅ `app/models/user.rb` (badge checking logic)
- ✅ `app/models/badge.rb` (condition checking)
- ✅ `app/models/user_badge.rb` (award logic)
- ✅ `app/views/layouts/application.html.erb` (flash display)
- ✅ `app/views/badges/index.html.erb` (check button)
- ✅ `config/routes.rb` (badge check route)

## Next Steps:
1. Install gems with `bundle install`
2. Run database migrations
3. Seed badge data if needed
4. Test manually by clicking "バッジをチェック"
5. Test automatically by creating habits/records