require 'test_helper'

class CalendarI18nTest < ActiveSupport::TestCase
  setup do
    @original_locale = I18n.locale
    I18n.locale = :ja
  end

  teardown do
    I18n.locale = @original_locale
  end

  test "Japanese day names are correctly configured" do
    expected_day_names = ["日", "月", "火", "水", "木", "金", "土"]
    assert_equal expected_day_names, I18n.t('date.abbr_day_names')
  end

  test "Japanese month names are correctly configured" do
    expected_month_names = ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"]
    # Skip the first nil element that Rails expects
    assert_equal expected_month_names, I18n.t('date.month_names')[1..-1]
  end

  test "default locale is set to Japanese" do
    assert_equal :ja, I18n.default_locale
  end

  test "available locales include Japanese and English" do
    assert_includes I18n.available_locales, :ja
    assert_includes I18n.available_locales, :en
  end
end