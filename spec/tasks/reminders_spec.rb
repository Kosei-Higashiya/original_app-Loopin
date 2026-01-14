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

    before do
      # 今週の活動を記録（active_userのみ）
      create(:habit_record, user: active_user, recorded_at: Time.current)
    end

    it 'sends emails only to inactive users' do
      expect { task.invoke }.to have_enqueued_job.on_queue('mailers').exactly(1)
    end

    it 'logs the sent emails' do
      expect(Rails.logger).to receive(:info).with(/Reminder email sent to user #{inactive_user.id}/)
      task.invoke
    end

    it 'does not send emails to active users' do
      task.invoke
      expect(ActionMailer::Base.deliveries.map(&:to).flatten).not_to include(active_user.email)
    end
  end
end
