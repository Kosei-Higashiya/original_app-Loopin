require 'rails_helper'

RSpec.describe '使い方ページ', type: :system do
  before do
    driven_by(:remote_chrome)
  end

  describe '使い方ページへのアクセス' do
    it 'ヘッダーの「使い方」リンクから使い方ページにアクセスできること' do
      visit root_path

      click_link '使い方'

      expect(page).to have_content('Loopinの使い方')
      expect(page).to have_content('はじめに')
      expect(page).to have_content('習慣を登録する')
      expect(page).to have_content('記録をつける')
      expect(page).to have_content('みんなの習慣を見る')
      expect(page).to have_content('バッジを獲得する')
      expect(page).to have_content('継続のコツ')
    end

    it 'ログインしていない場合、新規登録とログインボタンが表示されること' do
      visit how_to_use_path

      expect(page).to have_link('新規登録する')
      expect(page).to have_link('ログイン')
      expect(page).to have_link('無料で始める')
    end

    it 'ログインしている場合、ダッシュボードへのリンクが表示されること' do
      user = create(:user)
      sign_in user
      visit how_to_use_path

      expect(page).to have_link('ダッシュボードへ')
      expect(page).to have_link('習慣を登録する')
      expect(page).to have_link('習慣一覧へ')
      expect(page).to have_link('みんなの習慣を見る')
      expect(page).to have_link('投稿する')
      expect(page).to have_link('バッジ一覧を見る')
    end
  end
end
