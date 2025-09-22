FactoryBot.define do
  factory :user do
    name { "テストユーザー" }
    sequence(:email) { |n| "test#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }

    trait :with_name do
      name { "山田太郎" }
    end

    trait :guest do
      name { nil }
    end
  end
end