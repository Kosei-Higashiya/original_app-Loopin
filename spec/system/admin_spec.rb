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
        expect(page).to have_link('管理者モード', href: admin_posts_path)
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

      it '投稿管理画面にアクセスできないこと' do
        visit admin_posts_path
        expect(page).to have_content('管理者権限が必要です')
        expect(current_path).to eq(root_path)
      end
    end

    context 'ログインしていない場合' do
      it '投稿管理画面にアクセスできないこと' do
        visit admin_posts_path
        expect(current_path).to eq(new_user_session_path)
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
