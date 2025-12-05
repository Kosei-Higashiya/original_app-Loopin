require 'rails_helper'

RSpec.describe 'ナビゲーション', type: :system, js: true do
  before do
    driven_by(:remote_chrome)
  end

  describe 'ハンバーガーメニュー' do
    it 'モバイルビューでハンバーガーメニューが正しく動作すること', driver: :remote_chrome do
      # ブラウザのサイズを変更してモバイルビューをシミュレート
      page.driver.browser.manage.window.resize_to(375, 812)
      
      visit root_path
      
      # 最初はメニューが非表示であること
      expect(page).to have_css('.navbar-nav', visible: :hidden)
      
      # ハンバーガーボタンをクリック
      find('.navbar-toggler').click
      
      # メニューが表示されること
      expect(page).to have_css('.navbar-nav.active', visible: :visible)
      
      # もう一度クリックするとメニューが非表示になること
      find('.navbar-toggler').click
      expect(page).to have_css('.navbar-nav:not(.active)')
    end
    
    it 'デスクトップビューではメニューが常に表示されていること' do
      # デスクトップサイズに設定
      page.driver.browser.manage.window.resize_to(1024, 768)
      
      visit root_path
      
      # メニューが表示されていること
      expect(page).to have_css('.navbar-nav', visible: :visible)
      expect(page).to have_link('使い方')
    end
  end
end
