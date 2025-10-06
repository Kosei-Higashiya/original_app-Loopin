FactoryBot.define do
  factory :tag do
    name { 'ランニング' }

    trait :health do
      name { '健康' }
    end

    trait :fitness do
      name { 'フィットネス' }
    end
  end
end
