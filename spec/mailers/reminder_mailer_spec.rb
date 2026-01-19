require 'rails_helper'

RSpec.describe ReminderMailer, type: :mailer do
  describe '#weekly_reminder' do
    let(:user) { create(:user, name: '山田太郎', email: 'test@example.com') }
    let(:mail) { ReminderMailer.weekly_reminder(user) }

    it 'リマインダーメールを送信すること' do
      expect(mail.subject).to eq('【Loopin】今週の記録をつけましょう！')
    end

    it '正しい宛先にメールを送信すること' do
      expect(mail.to).to eq([user.email])
    end

    it '正しい送信元からメールを送信すること' do
      expect(mail.from).to eq(['noreply@loopin-app.com'])
    end

    it 'メール本文にユーザーの名前を含むこと' do
      expect(mail.html_part.body.to_s).to match(user.display_name)
      expect(mail.text_part.body.to_s).to match(user.display_name)
    end

    it 'メール本文に今週の記録に関するメッセージを含むこと' do
      expect(mail.html_part.body.to_s).to match(/今週はまだ習慣の記録をつけていないようです/)
      expect(mail.text_part.body.to_s).to match(/今週はまだ習慣の記録をつけていないようです/)
    end

    it 'メール本文にLoopinへのリンクを含むこと' do
      expect(mail.html_part.body.to_s).to match(/Loopinにアクセス/)
      expect(mail.text_part.body.to_s).to match(/Loopinにアクセス/)
    end

    context 'ユーザー名がない場合' do
      let(:user) { create(:user, :guest, email: 'guest@example.com') }

      it 'メール本文に「ゲスト」と表示されること' do
        expect(mail.html_part.body.to_s).to match('ゲスト')
        expect(mail.text_part.body.to_s).to match('ゲスト')
      end
    end
  end
end
