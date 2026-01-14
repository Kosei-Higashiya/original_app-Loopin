require 'rails_helper'
require 'rake'

RSpec.describe 'reminders:send_weekly', type: :task do
  before(:all) do
    Rake.application.rake_require 'tasks/reminders'
    Rake::Task.define_task(:environment)
  end

  let(:task) { Rake::Task['reminders:send_weekly'] }

  before do
    task.reenable
    ActiveJob::Base.queue_adapter = :test
  end

  describe 'send_weekly' do
    let!(:active_user) { create(:user, email: 'active@example.com') }
    let!(:inactive_user) { create(:user, email: 'inactive@example.com') }
    let!(:habit) { create(:habit, user: active_user) }

    before do
      # 今週の活動を記録（active_userのみ）
      create(:habit_record, user: active_user, habit: habit, recorded_at: Time.current)
    end

    it 'sends emails only to inactive users' do
      expect { task.invoke }.to have_enqueued_job(ActionMailer::MailDeliveryJob).exactly(1)
    end

    it 'logs the sent emails' do
      allow(Rails.logger).to receive(:info)
      task.invoke
      expect(Rails.logger).to have_received(:info).with(/Reminder email sent to user #{inactive_user.id}/)
    end

    it 'does not send emails to users who created posts this week' do
      # Create a post for another user
      user_with_post = create(:user, email: 'poster@example.com')
      post_habit = create(:habit, user: user_with_post)
      create(:post, user: user_with_post, habit: post_habit)
      
      task.reenable
      # Since user_with_post created a post, they shouldn't get an email
      # Only inactive_user should get an email (active_user has a habit_record)
      expect { task.invoke }.to have_enqueued_job(ActionMailer::MailDeliveryJob).exactly(1)
    end
  end
end
