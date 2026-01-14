namespace :reminders do
  desc '今週活動していないユーザーにリマインダーメールを送信'
  task send_weekly: :environment do
    # 今週の始まり（月曜日）を計算
    week_start = Time.current.beginning_of_week

    # 今週まだ記録をつけていないユーザーを取得
    inactive_users = User.where.not(
      id: HabitRecord.where('created_at >= ?', week_start).select(:user_id)
    ).where.not(
      id: Post.where('created_at >= ?', week_start).select(:user_id)
    )

    # 各ユーザーにリマインダーメールを送信
    inactive_users.find_each do |user|
      ReminderMailer.weekly_reminder(user).deliver_later
      Rails.logger.info "Reminder email sent to user #{user.id} (#{user.email})"
    end

    puts "Weekly reminder sent to #{inactive_users.count} inactive users"
  end
end
