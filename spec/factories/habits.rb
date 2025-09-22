FactoryBot.define do
  factory :habit do
    association :user
    title { 'Morning Exercise' }
    description { 'Daily 30-minute exercise routine' }
  end
end