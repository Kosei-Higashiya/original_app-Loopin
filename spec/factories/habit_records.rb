FactoryBot.define do
  factory :habit_record do
    habit
    user { habit.user }
    sequence(:recorded_at) { |n| Date.current - (n - 1).days }  # n=1は今日, n=2は昨日...
    completed { true }
    note { "今日もがんばりました！" }

    trait :incomplete do
      completed { false }
      note { "今日はできませんでした" }
    end

    trait :yesterday do
      recorded_at { 1.day.ago.to_date }
    end

    trait :last_week do
      recorded_at { 1.week.ago.to_date }
    end
  end
end
