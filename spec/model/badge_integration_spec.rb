require 'rails_helper'

# Integration test to verify badge awarding flow
RSpec.describe 'Badge awarding integration', type: :model do
  let(:user) { create(:user) }
  let(:habit) { create(:habit, user: user) }
  
  describe 'BadgeChecker integration with refactored code' do
    let!(:consecutive_badge) { create(:badge, :consecutive_days_badge, condition_value: 3) }
    let!(:total_records_badge) { create(:badge, condition_type: 'total_records', condition_value: 5) }
    let!(:total_habits_badge) { create(:badge, :total_habits_badge, condition_value: 2) }
    
    context 'when user earns badges through perform_badge_check_for_user' do
      it 'awards badges using the centralized award_badge method' do
        # Create conditions for consecutive days badge
        3.times do |i|
          create(:habit_record,
                 user: user,
                 habit: habit,
                 recorded_at: Date.current - i.days,
                 completed: true)
        end
        
        # Perform badge check (using BadgeChecker concern included in User)
        results = user.perform_badge_check_for_user(user)
        
        # Verify results structure
        expect(results).to have_key(:newly_earned)
        expect(results).to have_key(:errors)
        expect(results).to have_key(:stats)
        
        # Verify badge was awarded
        expect(results[:newly_earned].map(&:id)).to include(consecutive_badge.id)
        expect(user.badges.reload).to include(consecutive_badge)
        
        # Verify stats were calculated
        expect(results[:stats][:consecutive_days]).to eq(3)
        expect(results[:stats][:total_records]).to eq(3)
      end
      
      it 'awards multiple badges when multiple conditions are met' do
        # Create second habit to meet total_habits condition
        habit2 = create(:habit, user: user)
        
        # Create 5 records to meet total_records condition
        5.times do |i|
          create(:habit_record,
                 user: user,
                 habit: (i % 2 == 0 ? habit : habit2),
                 recorded_at: Date.current - i.days,
                 completed: true)
        end
        
        results = user.perform_badge_check_for_user(user)
        
        # Should award both total_records and total_habits badges
        earned_ids = results[:newly_earned].map(&:id)
        expect(earned_ids).to include(total_records_badge.id)
        expect(earned_ids).to include(total_habits_badge.id)
        
        # May also award consecutive_days badge if conditions are met
        # Verify badges are in database (at least 2)
        expect(user.badges.reload.count).to be >= 2
      end
      
      it 'does not award badges that are already earned (idempotent)' do
        # Create conditions for badge
        3.times do |i|
          create(:habit_record,
                 user: user,
                 habit: habit,
                 recorded_at: Date.current - i.days,
                 completed: true)
        end
        
        # First award
        results1 = user.perform_badge_check_for_user(user)
        expect(results1[:newly_earned].count).to eq(1)
        
        # Second award attempt (should be skipped)
        results2 = user.perform_badge_check_for_user(user)
        expect(results2[:newly_earned].count).to eq(0)
        
        # Badge count should remain 1
        expect(user.badges.reload.count).to eq(1)
      end
    end
    
    context 'when user calls check_and_award_badges' do
      it 'returns newly earned badges array for backward compatibility' do
        # Create first habit record
        create(:habit_record, user: user, habit: habit, recorded_at: Date.current, completed: true)
        
        # This method is used by controllers
        newly_earned = user.check_and_award_badges
        
        expect(newly_earned).to be_an(Array)
        expect(newly_earned).to be_empty # No badges meet condition with just 1 record
        
        # Create additional habits to add more records
        habit2 = create(:habit, user: user)
        habit3 = create(:habit, user: user)
        
        # Add more records to meet condition (5 total records needed)
        create(:habit_record, user: user, habit: habit2, recorded_at: Date.current, completed: true)
        create(:habit_record, user: user, habit: habit3, recorded_at: Date.current, completed: true)
        create(:habit_record, user: user, habit: habit2, recorded_at: Date.current - 1.day, completed: true)
        create(:habit_record, user: user, habit: habit3, recorded_at: Date.current - 1.day, completed: true)
        
        newly_earned = user.check_and_award_badges
        # Should award total_records badge (need 5 records)
        expect(newly_earned.count).to be >= 1
        expect(newly_earned.map(&:id)).to include(total_records_badge.id)
      end
    end
    
    context 'UserBadge.award_badge backward compatibility' do
      it 'works without user_stats parameter' do
        5.times { create(:habit_record, user: user, habit: habit) }
        
        # Old style call without user_stats
        result = UserBadge.award_badge(user, total_records_badge)
        
        expect(result).to be_a(UserBadge)
        expect(result.user).to eq(user)
        expect(result.badge).to eq(total_records_badge)
      end
      
      it 'works with user_stats parameter (new style)' do
        user_stats = {
          consecutive_days: 1,
          total_habits: 1,
          total_records: 5,
          completion_rate: 80.0
        }
        
        # New style call with user_stats
        result = UserBadge.award_badge(user, total_records_badge, user_stats: user_stats)
        
        expect(result).to be_a(UserBadge)
        expect(result.user).to eq(user)
        expect(result.badge).to eq(total_records_badge)
      end
    end
  end
end
