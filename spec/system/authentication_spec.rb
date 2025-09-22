require 'rails_helper'

RSpec.describe 'ユーザー認証', type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  describe 'ユーザー登録' do
    it '新しいユーザーがアカウントを作成できること' do
      visit new_user_registration_path

      fill_in 'user[name]', with: '山田太郎'
      fill_in 'user[email]', with: 'yamada@example.com'
      fill_in 'user[password]', with: 'password123'
      fill_in 'user[password_confirmation]', with: 'password123'

      click_button 'アカウント登録'

      expect(page).to have_content('アカウント登録が完了しました')
    end

    it 'パスワードが短すぎる場合はエラーが表示されること' do
      visit new_user_registration_path

      fill_in 'user[email]', with: 'test@example.com'
      fill_in 'user[password]', with: '123'
      fill_in 'user[password_confirmation]', with: '123'

      click_button 'アカウント登録'

      expect(page).to have_content('は6文字以上で入力してください')
    end
  end

  describe 'ログイン' do
    let(:user) { create(:user, email: 'test@example.com', password: 'password123') }

    it 'ユーザーがログインできること' do
      visit new_user_session_path

      fill_in 'user[email]', with: 'test@example.com'
      fill_in 'user[password]', with: 'password123'

      click_button 'ログイン'

      expect(page).to have_content('ログインしました')
    end

    it '間違った認証情報ではログインできないこと' do
      visit new_user_session_path

      fill_in 'user[email]', with: 'test@example.com'
      fill_in 'user[password]', with: 'wrongpassword'

      click_button 'ログイン'

      expect(page).to have_content('メールアドレスもしくはパスワードが不正です')
    end
  end

  describe 'ログアウト' do
    let(:user) { create(:user) }

    it 'ユーザーがログアウトできること' do
      sign_in user
      visit root_path

      click_link 'ログアウト'

      expect(page).to have_content('ログアウトしました')
    end
  end
end