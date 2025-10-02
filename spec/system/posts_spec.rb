require 'rails_helper'

RSpec.describe 'SNS機能（投稿・いいね）', type: :system do
  let(:user) { create(:user) }
  let(:habit) { create(:habit, user: user) }

  before do
    driven_by(:remote_chrome)
    sign_in user
  end

  describe '投稿作成' do
    it 'ユーザーが習慣に関する投稿を作成できること' do
      visit new_post_path

      select habit.title, from: 'post[habit_id]'
      fill_in 'post[content]', with: '今日のランニングはとても気持ちよかったです！'

      click_button '投稿'

      expect(page).to have_content('投稿が作成されました')
      expect(page).to have_content('今日のランニングはとても気持ちよかったです！')
    end

    it '内容が空の場合はエラーが表示されること' do
      visit new_post_path

      select habit.title, from: 'post[habit_id]'
      click_button '投稿'

      expect(page).to have_content('を入力してください')
    end
  end

  describe '投稿一覧・いいね機能' do
    let(:other_user) { create(:user, name: '他のユーザー') }
    let!(:post) { create(:post, user: other_user, habit: create(:habit, user: other_user)) }

    it '他のユーザーの投稿が表示されること' do
      visit posts_path

      expect(page).to have_content(post.content)
      expect(page).to have_content('他のユーザー')
    end

    it '投稿にいいねできること', js: true do
      visit posts_path

      within("#post_#{post.id}") do
        click_link '♡'
      end

      expect(page).to have_content('♥')
    end

    it 'いいねした投稿一覧を表示できること' do
      create(:like, user: user, post: post)

      visit liked_posts_path

      expect(page).to have_content(post.content)
    end
  end
end
