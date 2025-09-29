require 'rails_helper'

RSpec.describe Company, type: :model do
  describe "驗證" do
    it "需要公司名稱" do
      company = build(:company, name: nil)
      expect(company).not_to be_valid
      expect(company.errors[:name]).to include("can't be blank")
    end

    it "公司名稱必須唯一" do
      create(:company, name: "測試公司")
      company = build(:company, name: "測試公司")
      expect(company).not_to be_valid
      expect(company.errors[:name]).to include("has already been taken")
    end
  end

  describe "關聯" do
    it "透過 user_companies 與多個使用者建立關聯" do
      company = create(:company)
      user1 = create(:user)
      user2 = create(:user)

      create(:user_company, user: user1, company: company)
      create(:user_company, user: user2, company: company)

      expect(company.users).to include(user1, user2)
      expect(company.users.count).to eq(2)
    end

    it "刪除時同時刪除相關的 user_companies" do
      company = create(:company)
      user = create(:user)
      user_company = create(:user_company, user: user, company: company)

      expect {
        company.destroy
      }.to change(UserCompany, :count).by(-1)
    end
  end

  describe "工廠" do
    it "可以建立有效的公司" do
      company = build(:company)
      expect(company).to be_valid
    end
  end
end