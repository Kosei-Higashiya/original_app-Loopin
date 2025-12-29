FactoryBot.define do
  factory :user do
    sequence(:name)  { |n| "ユーザー#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" } # ← ユニーク化
    password { 'password123' }
    password_confirmation { 'password123' }

    trait :with_name do
      name { '山田太郎' }
    end

    trait :guest do
      name { nil }
    end

    trait :oauth_user do
      provider { 'google_oauth2' }
      uid { '123456789' }
      password { nil }
    end

    trait :admin do
      admin { true }
    end
  end
end
