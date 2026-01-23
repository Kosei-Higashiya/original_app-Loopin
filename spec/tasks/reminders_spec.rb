require 'rails_helper'
require 'rake'

RSpec.describe 'reminders:send_weekly', type: :task do
  before(:all) do
    # Rakeタスクをロード
    Rake.application.rake_require 'tasks/reminders'
    Rake::Task.define_task(:environment)
  end

  before do
    # タスクを再有効化（テスト間で再実行可能にする）
    Rake::Task['reminders:send_weekly'].reenable
  end

  let(:last_week_start) { Date.current.beginning_of_week - 1.week }
  let(:last_week_end) { last_week_start.end_of_week }

  describe '先週活動していないユーザーへのリマインダー送信' do
    context '先週記録をつけていないユーザーが存在する場合' do
      let!(:inactive_user) { create(:user, email: 'inactive@example.com') }

      before do
        # 先週の記録は作成しない
        # ActiveJobのテストヘルパーを使用
        ActiveJob::Base.queue_adapter = :test
      end

      it 'リマインダーメールが送信されること' do
        expect {
          Rake::Task['reminders:send_weekly'].invoke
        }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
          .with('ReminderMailer', 'weekly_reminder', 'deliver_now', { args: [inactive_user] })
      end
    end

    context '先週HabitRecordを作成したユーザーがいる場合' do
      let!(:active_user) { create(:user, email: 'active@example.com') }
      let!(:habit) { create(:habit, user: active_user) }
      let!(:habit_record) { create(:habit_record, user: active_user, habit: habit, recorded_at: last_week_start) }

      before do
        ActiveJob::Base.queue_adapter = :test
      end

      it 'そのユーザーにはリマインダーメールが送信されないこと' do
        expect {
          Rake::Task['reminders:send_weekly'].invoke
        }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)
          .with('ReminderMailer', 'weekly_reminder', 'deliver_now', { args: [active_user] })
      end
    end

    context '先週Postを作成したユーザーがいる場合' do
      let!(:active_user) { create(:user, email: 'poster@example.com') }
      let!(:habit) { create(:habit, user: active_user) }
      let!(:post) { create(:post, user: active_user, habit: habit, created_at: last_week_start.to_time) }

      before do
        ActiveJob::Base.queue_adapter = :test
      end

      it 'そのユーザーにはリマインダーメールが送信されないこと' do
        expect {
          Rake::Task['reminders:send_weekly'].invoke
        }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)
          .with('ReminderMailer', 'weekly_reminder', 'deliver_now', { args: [active_user] })
      end
    end

    context '先週活動していないユーザーと活動しているユーザーが混在する場合' do
      let!(:inactive_user1) { create(:user, email: 'inactive1@example.com') }
      let!(:inactive_user2) { create(:user, email: 'inactive2@example.com') }
      let!(:active_user) { create(:user, email: 'active@example.com') }
      let!(:habit) { create(:habit, user: active_user) }
      let!(:habit_record) { create(:habit_record, user: active_user, habit: habit, recorded_at: last_week_start) }

      before do
        ActiveJob::Base.queue_adapter = :test
      end

      it '活動していないユーザーにのみリマインダーメールが送信されること' do
        Rake::Task['reminders:send_weekly'].invoke

        # 非活動ユーザーへのメール送信を確認
        expect(ActionMailer::MailDeliveryJob).to have_been_enqueued.with(
          'ReminderMailer', 'weekly_reminder', 'deliver_now', { args: [inactive_user1] }
        )
        expect(ActionMailer::MailDeliveryJob).to have_been_enqueued.with(
          'ReminderMailer', 'weekly_reminder', 'deliver_now', { args: [inactive_user2] }
        )

        # 活動ユーザーへのメール送信がないことを確認
        expect(ActionMailer::MailDeliveryJob).not_to have_been_enqueued.with(
          'ReminderMailer', 'weekly_reminder', 'deliver_now', { args: [active_user] }
        )
      end
    end

    context '2週間前に記録をつけたが先週はつけていないユーザーがいる場合' do
      let!(:two_weeks_ago_user) { create(:user, email: 'twoweeksago@example.com') }
      let!(:habit) { create(:habit, user: two_weeks_ago_user) }
      let!(:two_weeks_ago_record) { create(:habit_record, user: two_weeks_ago_user, habit: habit, recorded_at: 2.weeks.ago.to_date) }

      before do
        ActiveJob::Base.queue_adapter = :test
      end

      it 'そのユーザーにリマインダーメールが送信されること' do
        expect {
          Rake::Task['reminders:send_weekly'].invoke
        }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
          .with('ReminderMailer', 'weekly_reminder', 'deliver_now', { args: [two_weeks_ago_user] })
      end
    end
  end
end
