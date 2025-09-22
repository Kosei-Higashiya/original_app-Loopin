FactoryBot.define do
  factory :badge do
    name { "初回達成" }
    description { "初めて習慣を記録した時に獲得できるバッジです" }
    condition_type { "total_records" }
    condition_value { 1 }
    icon { "🎉" }
    active { true }

    trait :consecutive_days_badge do
      name { "7日連続" }
      description { "7日連続で習慣を実行した時に獲得できるバッジです" }
      condition_type { "consecutive_days" }
      condition_value { 7 }
      icon { "🔥" }
    end

    trait :total_habits_badge do
      name { "習慣マスター" }
      description { "5つの習慣を作成した時に獲得できるバッジです" }
      condition_type { "total_habits" }
      condition_value { 5 }
      icon { "⭐" }
    end

    trait :inactive do
      active { false }
    end
  end
end