#!/usr/bin/env ruby
require 'ostruct'
require_relative 'config/environment'

# Test the notification system
puts "Testing badge notification duplication fix..."

# Simulate shared session storage (like Redis or database)
$shared_session = {}

# Create test controller to simulate request behavior
class TestController < ActionController::Base
  include BadgeNotifications
  
  def initialize(shared_session)
    @session = shared_session  # Share session between requests
    @flash = {}  # Flash should be new for each request
    @request = OpenStruct.new(
      format: OpenStruct.new(turbo_stream?: false),
      xhr?: false
    )
  end
  
  attr_reader :session, :flash, :request
end

def test_notification_flow
  # Clean up first
  Badge.destroy_all
  $shared_session.clear
  
  # Simulate earning a badge
  badge = Badge.create!(
    name: 'Test Badge',
    description: 'A test badge',
    condition_type: 'total_habits',
    condition_value: 1,
    active: true
  )
  
  puts "\nBadge created: #{badge.name}"
  
  puts "\n1. Setting badge notification in session..."
  controller1 = TestController.new($shared_session)
  controller1.send(:set_badge_notification, [badge])
  puts "Session after set: #{$shared_session.inspect}"
  
  puts "\n2. First request - set_badge_notification_flash..."
  controller2 = TestController.new($shared_session)  # New controller instance
  controller2.send(:set_badge_notification_flash)
  puts "Flash after first call: #{controller2.flash.inspect}"
  puts "Session after first call: #{$shared_session.inspect}"
  
  puts "\n3. Second request - set_badge_notification_flash (simulating second page request)..."
  controller3 = TestController.new($shared_session)  # New controller instance
  controller3.send(:set_badge_notification_flash)
  puts "Flash after second call: #{controller3.flash.inspect}"
  puts "Session after second call: #{$shared_session.inspect}"
  
  puts "\n4. Third request - set_badge_notification_flash (simulating third page request)..."
  controller4 = TestController.new($shared_session)  # New controller instance
  controller4.send(:set_badge_notification_flash)
  puts "Flash after third call: #{controller4.flash.inspect}"
  puts "Session after third call: #{$shared_session.inspect}"
  
  puts "\n5. Adding a new badge (should reset processed flag)..."
  badge2 = Badge.create!(
    name: 'Another Badge',
    description: 'Another test badge',
    condition_type: 'total_habits',
    condition_value: 2,
    active: true
  )
  puts "Badge2 created: #{badge2.name}"
  controller5 = TestController.new($shared_session)
  controller5.send(:set_badge_notification, [badge2])
  puts "Session after adding new badge: #{$shared_session.inspect}"
  
  puts "\n6. Flash notification call after new badge..."
  controller6 = TestController.new($shared_session)  # New controller instance
  controller6.send(:set_badge_notification_flash)
  puts "Flash after new badge call: #{controller6.flash.inspect}"
  puts "Session after new badge call: #{$shared_session.inspect}"
end

# Run test
test_notification_flow