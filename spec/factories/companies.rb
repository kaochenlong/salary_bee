FactoryBot.define do
  factory :company do
    sequence(:name) { |n| "公司 #{n}" }
    sequence(:tax_id) do |n|
      valid_tax_ids = [ "10458575", "88117125", "53212539" ]
      valid_tax_ids[n % valid_tax_ids.length]
    end
    description { "這是一家測試公司，專門從事軟體開發業務。" }
  end
end