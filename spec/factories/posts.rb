FactoryBot.define do
  factory :post do
    association :user
    association :habit
    content { 'This is a test post about my habit progress.' }
    
    trait :with_tags do
      after(:create) do |post|
        post.tags << create_list(:tag, 2)
      end
    end
  end
end