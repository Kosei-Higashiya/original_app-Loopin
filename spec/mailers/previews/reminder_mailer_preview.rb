# Preview all emails at http://localhost:3000/rails/mailers/reminder_mailer
class ReminderMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/reminder_mailer/weekly_reminder
  def weekly_reminder
    user = User.first || User.new(name: 'サンプルユーザー', email: 'sample@example.com')
    ReminderMailer.weekly_reminder(user)
  end

end
