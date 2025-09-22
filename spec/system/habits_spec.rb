require 'rails_helper'

RSpec.describe '習慣管理', type: :system do
  let(:user) { create(:user) }

  before do
    driven_by(:selenium_chrome_headless)
    sign_in user
  end

  describe '習慣作成' do
    it 'ユーザーが新しい習慣を作成できること' do
      visit new_habit_path

      fill_in 'habit[title]', with: '毎日ランニング'
      fill_in 'habit[description]', with: '健康のために毎日30分ランニングする'

      click_button '習慣を作成'

      expect(page).to have_content('習慣が作成されました！')
      expect(page).to have_content('毎日ランニング')
    end

    it 'タイトルが空の場合はエラーが表示されること' do
      visit new_habit_path

      fill_in 'habit[description]', with: '健康のために毎日30分ランニングする'
      click_button '習慣を作成'

      expect(page).to have_content('を入力してください')
    end
  end

  describe '習慣一覧' do
    let!(:habit1) { create(:habit, user: user, title: 'ランニング') }
    let!(:habit2) { create(:habit, user: user, title: '読書') }

    it 'ユーザーの習慣一覧が表示されること' do
      visit habits_path

      expect(page).to have_content('ランニング')
      expect(page).to have_content('読書')
    end
  end

  describe '習慣詳細・記録' do
    let!(:habit) { create(:habit, user: user, title: '毎日ランニング') }

    it '習慣の詳細が表示されること' do
      visit habit_path(habit)

      expect(page).to have_content('毎日ランニング')
    end

    it '習慣を編集できること' do
      visit edit_habit_path(habit)

      fill_in 'habit[title]', with: '毎日ウォーキング'
      click_button '習慣を更新'

      expect(page).to have_content('習慣が正常に更新されました')
      expect(page).to have_content('毎日ウォーキング')
    end

    it '習慣を削除できること' do
      visit habit_path(habit)

      click_link '削除'

      expect(page).to have_content('習慣が削除されました')
      expect(page).not_to have_content('毎日ランニング')
    end
  end
end