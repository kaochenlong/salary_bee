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

    it "需要統一編號" do
      company = build(:company, tax_id: nil)
      expect(company).not_to be_valid
      expect(company.errors[:tax_id]).to include("can't be blank")
    end

    it "統一編號必須唯一" do
      create(:company, tax_id: "10458575")
      company = build(:company, tax_id: "10458575")
      expect(company).not_to be_valid
      expect(company.errors[:tax_id]).to include("has already been taken")
    end

    it "統一編號必須是 8 位數字" do
      company = build(:company, tax_id: "1234567")
      expect(company).not_to be_valid
      expect(company.errors[:tax_id]).to include("必須是 8 位數字")
    end

    it "統一編號不可包含非數字字元" do
      company = build(:company, tax_id: "1234567a")
      expect(company).not_to be_valid
      expect(company.errors[:tax_id]).to include("必須是 8 位數字")
    end

    it "驗證台灣統一編號檢查碼" do
      # 有效的統編
      valid_tax_ids = [ "10458575", "88117125", "53212539" ]
      valid_tax_ids.each do |tax_id|
        company = build(:company, tax_id: tax_id)
        expect(company).to be_valid, "#{tax_id} 應該是有效的統編"
      end

      # 無效的統編：檢查碼錯誤
      company = build(:company, tax_id: "88117126")
      expect(company).not_to be_valid
      expect(company.errors[:tax_id]).to include("統一編號格式不正確")
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