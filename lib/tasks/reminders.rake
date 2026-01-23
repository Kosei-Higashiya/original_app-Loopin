namespace :reminders do
  desc '先週活動していないユーザーにリマインダーメールを送信'
  task send_weekly: :environment do
    # 先週の期間を計算（先週の月曜日から日曜日まで）
    last_week_start = Date.current.beginning_of_week - 1.week
    last_week_end = last_week_start.end_of_week

    # 先週記録をつけていないユーザーを取得
    inactive_users = User.where.not(
      id: HabitRecord.where(recorded_at: last_week_start..last_week_end).select(:user_id)
    ).where.not(
      id: Post.where(created_at: last_week_start.beginning_of_day..last_week_end.end_of_day).select(:user_id)
    )

    # 各ユーザーにリマインダーメールを送信
    inactive_users.find_each do |user|
      ReminderMailer.weekly_reminder(user).deliver_later
      Rails.logger.info "Reminder email sent to user #{user.id} (#{user.email})"
    end

    puts "Weekly reminder sent to #{inactive_users.count} inactive users"
  end
end
