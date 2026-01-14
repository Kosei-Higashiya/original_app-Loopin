# Preview all emails at http://localhost:3000/rails/mailers/reminder_mailer_mailer
class ReminderMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/reminder_mailer_mailer/weekly_reminder
  def weekly_reminder
    ReminderMailer.weekly_reminder
  end

end
