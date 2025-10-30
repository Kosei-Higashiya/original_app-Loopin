require 'rails_helper'
require 'active_job/test_helper'

RSpec.describe 'パスワードリセット', type: :system do
  include ActiveJob::TestHelper

  before do
    driven_by(:remote_chrome)
  end

  let!(:user) { create(:user, email: 'test@example.com', password: 'password123') }

  describe 'パスワードリセットリクエスト' do
    it 'パスワードリセットページにアクセスできること' do
      visit new_user_password_path

      expect(page).to have_content('パスワード再設定')
      expect(page).to have_field('メールアドレス')
      expect(page).to have_button('パスワード再設定メールを送信')
    end

    it 'パスワードリセットメールをリクエストできること', skip: '一時的に無効化' do
      visit new_user_password_path

      fill_in 'メールアドレス', with: 'test@example.com'

      # メールが送信されることを確認
      perform_enqueued_jobs do
        expect {
          click_button 'パスワード再設定メールを送信'
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      expect(page).to have_content('パスワード再設定の手順')
    end

    it '登録されていないメールアドレスでもエラーを表示しないこと（セキュリティのため）' do
      visit new_user_password_path

      fill_in 'メールアドレス', with: 'nonexistent@example.com'
      click_button 'パスワード再設定メールを送信'

      # Deviseのデフォルトではメールアドレスが存在しない場合でも同じメッセージを表示
      expect(page).to have_content('パスワード再設定の手順')
    end
  end

  describe 'パスワードリセット実行' do
    it 'リセットトークンを使用して新しいパスワードを設定できること', skip: '一時的に無効化' do
      # パスワードリセットトークンを生成
      token = user.send_reset_password_instructions

      # パスワード編集ページにアクセス
      visit edit_user_password_path(reset_password_token: token)

      expect(page).to have_content('新しいパスワード設定')

      # 新しいパスワードを入力
      fill_in 'user[password]', with: 'newpassword123'
      fill_in 'user[password_confirmation]', with: 'newpassword123'

      click_button 'パスワードを変更'

      expect(page).to have_content('パスワードが正常に変更されました。')

      # 新しいパスワードでログインできることを確認
      click_link 'ログアウト' if page.has_link?('ログアウト')

      visit new_user_session_path
      fill_in 'メールアドレス', with: 'test@example.com'
      fill_in 'パスワード', with: 'newpassword123'
      click_button 'ログイン'

      expect(page).to have_content('ログインしました。')
    end

    it 'パスワードが短すぎる場合はエラーが表示されること' do
      token = user.send_reset_password_instructions

      visit edit_user_password_path(reset_password_token: token)

      fill_in 'user[password]', with: '123'
      fill_in 'user[password_confirmation]', with: '123'

      click_button 'パスワードを変更'

      expect(page).to have_content('は6文字以上で入力してください')
    end

    it 'パスワードと確認が一致しない場合はエラーが表示されること' do
      token = user.send_reset_password_instructions

      visit edit_user_password_path(reset_password_token: token)

      fill_in 'user[password]', with: 'newpassword123'
      fill_in 'user[password_confirmation]', with: 'differentpassword'

      click_button 'パスワードを変更'

      expect(page).to have_content('確認用パスワードとパスワードの入力が一致しません')
    end
  end

  describe 'OAuthユーザー' do
    let!(:oauth_user) { create(:user, provider: 'google_oauth2', uid: '123456', email: 'oauth@example.com') }

    it 'OAuthユーザーはパスワードリセットをリクエストしても影響がないこと' do
      # OAuthユーザーはパスワードを持たないため、リセットは無意味だが
      # システムとしては正常にメッセージを返す（セキュリティのため）
      visit new_user_password_path

      fill_in 'メールアドレス', with: 'oauth@example.com'
      click_button 'パスワード再設定メールを送信'

      expect(page).to have_content('パスワード再設定の手順をメールでお送りしました。')
    end
  end
end
