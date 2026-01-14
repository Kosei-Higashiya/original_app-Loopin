class ReminderMailer < ApplicationMailer
  # 週次リマインダーを送信する
  # @param user [User] リマインダーを送信するユーザー
  def weekly_reminder(user)
    @user = user
    mail(
      to: user.email,
      subject: '【Loopin】今週の記録をつけましょう！'
    )
  end
end
