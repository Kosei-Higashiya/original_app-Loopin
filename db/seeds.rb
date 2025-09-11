# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# バッジの作成
badges_data = [
  {
    name: "初回習慣",
    description: "最初の習慣を作成しました",
    condition_type: "total_habits",
    condition_value: 1,
    icon: "🎯"
  },
  {
    name: "習慣コレクター",
    description: "3つの習慣を作成しました",
    condition_type: "total_habits", 
    condition_value: 3,
    icon: "📝"
  },
  {
    name: "習慣マスター",
    description: "5つの習慣を作成しました",
    condition_type: "total_habits",
    condition_value: 5,
    icon: "⭐"
  },
  {
    name: "3日間継続",
    description: "3日間連続で記録しました",
    condition_type: "consecutive_days",
    condition_value: 3,
    icon: "🔥"
  },
  {
    name: "1週間継続",
    description: "7日間連続で記録しました", 
    condition_type: "consecutive_days",
    condition_value: 7,
    icon: "💪"
  },
  {
    name: "1ヶ月継続",
    description: "30日間連続で記録しました",
    condition_type: "consecutive_days",
    condition_value: 30,
    icon: "🏆"
  },
  {
    name: "記録スタート",
    description: "10回記録しました",
    condition_type: "total_records",
    condition_value: 10,
    icon: "📊"
  },
  {
    name: "記録王",
    description: "100回記録しました",
    condition_type: "total_records",
    condition_value: 100,
    icon: "👑"
  },
  {
    name: "完璧主義者",
    description: "完了率90%以上を達成しました",
    condition_type: "completion_rate",
    condition_value: 90,
    icon: "✨"
  }
]

badges_data.each do |badge_data|
  Badge.find_or_create_by!(name: badge_data[:name]) do |badge|
    badge.description = badge_data[:description]
    badge.condition_type = badge_data[:condition_type]
    badge.condition_value = badge_data[:condition_value]
    badge.icon = badge_data[:icon]
    badge.active = true
  end
end

puts "Created #{Badge.count} badges"
