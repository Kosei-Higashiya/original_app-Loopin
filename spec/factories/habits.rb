FactoryBot.define do
  factory :habit do
    title { "毎日ランニング" }
    description { "健康のために毎日30分ランニングする" }
    user

    trait :with_long_description do
      description { "健康のために毎日30分ランニングする。朝の時間帯に行うことで一日のスタートを良くする。継続することで体力向上を目指す。" }
    end

    trait :simple do
      title { "読書" }
      description { "本を読む" }
    end
  end
end
