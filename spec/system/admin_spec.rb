require 'rails_helper'

RSpec.describe '管理者モード', type: :system do
  before do
    driven_by(:remote_chrome)
  end

  let!(:admin_user) { create(:user, :admin, email: 'admin@example.com', password: 'password123') }
  let!(:normal_user) { create(:user, email: 'user@example.com', password: 'password123') }
  let!(:post1) { create(:post, user: normal_user) }
  let!(:post2) { create(:post, user: admin_user) }

  describe '管理者権限のチェック' do
    context '管理者ユーザーの場合' do
      before do
        visit new_user_session_path
        fill_in 'user[email]', with: 'admin@example.com'
        fill_in 'user[password]', with: 'password123'
        click_button 'ログイン'
      end

      it '管理者モードのリンクが表示されること' do
        expect(page).to have_link('管理者モード', href: admin_users_path)
      end

      it 'ユーザー管理画面にアクセスできること' do
        visit admin_users_path
        expect(page).to have_content('管理者モード - ユーザー管理')
        expect(page).to have_content(admin_user.email)
        expect(page).to have_content(normal_user.email)
      end

      it '投稿管理画面にアクセスできること' do
        visit admin_posts_path
        expect(page).to have_content('管理者モード - 投稿管理')
        expect(page).to have_content(post1.content)
        expect(page).to have_content(post2.content)
      end
    end

    context '一般ユーザーの場合' do
      before do
        visit new_user_session_path
        fill_in 'user[email]', with: 'user@example.com'
        fill_in 'user[password]', with: 'password123'
        click_button 'ログイン'
      end

      it '管理者モードのリンクが表示されないこと' do
        expect(page).not_to have_link('管理者モード')
      end

      it 'ユーザー管理画面にアクセスできないこと' do
        visit admin_users_path
        expect(page).to have_content('管理者権限が必要です')
        expect(current_path).to eq(root_path)
      end

      it '投稿管理画面にアクセスできないこと' do
        visit admin_posts_path
        expect(page).to have_content('管理者権限が必要です')
        expect(current_path).to eq(root_path)
      end
    end

    context 'ログインしていない場合' do
      it 'ユーザー管理画面にアクセスできないこと' do
        visit admin_users_path
        expect(current_path).to eq(new_user_session_path)
      end
    end
  end

  describe 'ユーザー削除機能' do
    before do
      visit new_user_session_path
      fill_in 'user[email]', with: 'admin@example.com'
      fill_in 'user[password]', with: 'password123'
      click_button 'ログイン'
      visit admin_users_path
    end

    it '一般ユーザーを削除できること' do
      expect(page).to have_content(normal_user.email)
      
      # Find the delete button for the specific user
      within("tr", text: normal_user.email) do
        accept_confirm do
          click_button '削除'
        end
      end

      expect(page).to have_content('ユーザーを削除しました')
      expect(page).not_to have_content(normal_user.email)
      expect(User.exists?(normal_user.id)).to be_falsey
    end

    it '管理者ユーザーは削除ボタンが表示されないこと' do
      within("tr", text: admin_user.email) do
        expect(page).not_to have_button('削除')
      end
    end

    it '別の管理者ユーザーも削除ボタンが表示されないこと' do
      other_admin = create(:user, :admin, email: 'admin2@example.com')
      visit admin_users_path
      
      within("tr", text: other_admin.email) do
        expect(page).not_to have_button('削除')
      end
    end
  end

  describe '投稿削除機能' do
    before do
      visit new_user_session_path
      fill_in 'user[email]', with: 'admin@example.com'
      fill_in 'user[password]', with: 'password123'
      click_button 'ログイン'
      visit admin_posts_path
    end

    it '投稿を削除できること' do
      expect(page).to have_content(post1.content)
      
      # Find the delete button for the specific post
      within("tr", text: post1.content) do
        accept_confirm do
          click_button '削除'
        end
      end

      expect(page).to have_content('投稿を削除しました')
      expect(page).not_to have_content(post1.content)
      expect(Post.exists?(post1.id)).to be_falsey
    end
  end
end
