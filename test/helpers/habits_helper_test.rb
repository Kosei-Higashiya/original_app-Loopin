require 'test_helper'

class HabitsHelperTest < ActionView::TestCase
  include HabitsHelper

  setup do
    @original_locale = I18n.locale
    I18n.locale = :ja
  end

  teardown do
    I18n.locale = @original_locale
  end

  test "calendar_title returns Japanese formatted date" do
    test_date = Date.new(2025, 9, 6)
    expected_title = "2025年09月"
    
    assert_equal expected_title, calendar_title(test_date)
  end

  test "calendar_title uses I18n localization" do
    test_date = Date.new(2025, 12, 25)
    result = calendar_title(test_date)
    
    # Should contain Japanese characters
    assert_match(/年/, result)
    assert_match(/月/, result)
    assert_equal "2025年12月", result
  end
end