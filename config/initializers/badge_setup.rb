# Ensure test badge exists for testing badge functionality
Rails.application.config.after_initialize do
  if Badge.table_exists?
    test_badge = Badge.find_or_create_by(name: 'テスト用バッジ') do |badge|
      badge.description = 'バッジ機能をテストするためのバッジです。誰でも獲得できます。'
      badge.condition_type = 'total_habits'
      badge.condition_value = 0
      badge.icon = '🎉'
      badge.active = true
    end

    Rails.logger.info "Test badge ensured: #{test_badge.name} (ID: #{test_badge.id})" if test_badge.persisted?
  end
rescue StandardError => e
  Rails.logger.warn "Could not create test badge: #{e.message}"
end
