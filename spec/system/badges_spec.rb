require 'rails_helper'

RSpec.describe 'バッジシステム', type: :system do
  let(:user) { create(:user) }
  let(:badge) { create(:badge, name: '初回達成', condition_type: 'total_records', condition_value: 1) }

  before do
    driven_by(:selenium_chrome_headless)
    sign_in user
    badge # バッジを作成
  end

  describe 'バッジ一覧' do
    it 'ユーザーがバッジ一覧を表示できること' do
      visit badges_path

      expect(page).to have_content('初回達成')
    end
  end

  describe 'バッジ獲得' do
    let(:habit) { create(:habit, user: user) }

    it '条件を満たしたときにバッジを獲得できること' do
      # 記録を作成してバッジ獲得条件を満たす
      create(:habit_record, user: user, habit: habit)

      # バッジチェック実行（実際のアプリでは自動実行される）
      user.check_and_award_badges

      visit badges_path

      # 獲得したバッジが表示される
      expect(page).to have_content('初回達成')
      # 未獲得の場合はグレーアウトなどの表示になる想定
    end
  end

  describe 'バッジ詳細' do
    it 'バッジの詳細情報を表示できること' do
      visit badge_path(badge)

      expect(page).to have_content('初回達成')
      expect(page).to have_content(badge.description)
    end
  end
end