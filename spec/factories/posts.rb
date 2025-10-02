FactoryBot.define do
  factory :post do
    content { "今日のランニング、とても気持ちよかったです！継続頑張ります。" }
    user
    habit

    trait :short do
      content { "完了！" }
    end

    trait :with_long_content do
      content { "今日のランニングは特に素晴らしかったです。天気も良く、気温も適度で、とても気持ちよく走ることができました。これからも継続していきます。" * 3 }
    end
  end
end
