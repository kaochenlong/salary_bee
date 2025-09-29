FactoryBot.define do
  factory :company do
    sequence(:name) { |n| "公司 #{n}" }
    description { "這是一家測試公司，專門從事軟體開發業務。" }
  end
end