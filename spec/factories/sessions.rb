FactoryBot.define do
  factory :session do
    association :user
    ip_address { "127.0.0.1" }
    user_agent { "Test Browser" }
  end
end
