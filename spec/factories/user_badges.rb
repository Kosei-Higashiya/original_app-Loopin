FactoryBot.define do
  factory :user_badge do
    association :user
    association :badge
    earned_at { Time.current }
  end
end
