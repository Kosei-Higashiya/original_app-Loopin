require "rails_helper"

RSpec.describe ReminderMailer, type: :mailer do
  describe "weekly_reminder" do
    let(:user) { create(:user, email: 'test@example.com', name: 'テストユーザー') }
    let(:mail) { ReminderMailer.weekly_reminder(user) }

    it "renders the headers" do
      expect(mail.subject).to eq("【Loopin】今週の記録をつけましょう！")
      expect(mail.to).to eq(["test@example.com"])
      expect(mail.from).to eq(["noreply@loopin-app.com"])
    end

    it "renders the body with user name" do
      expect(mail.html_part.decoded).to match(user.display_name)
      expect(mail.text_part.decoded).to match(user.display_name)
    end

    it "includes the root URL in the body" do
      expect(mail.html_part.decoded).to match(/http/)
      expect(mail.text_part.decoded).to match(/http/)
    end
  end

end
