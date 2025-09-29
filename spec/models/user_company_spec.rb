require 'rails_helper'

RSpec.describe UserCompany, type: :model do
  describe "關聯" do
    it "屬於使用者" do
      user_company = build(:user_company)
      expect(user_company.user).to be_present
    end

    it "屬於公司" do
      user_company = build(:user_company)
      expect(user_company.company).to be_present
    end
  end

  describe "驗證" do
    it "同一使用者不能重複加入同一公司" do
      user = create(:user)
      company = create(:company)
      create(:user_company, user: user, company: company)

      duplicate_user_company = build(:user_company, user: user, company: company)
      expect(duplicate_user_company).not_to be_valid
      expect(duplicate_user_company.errors[:user_id]).to include("has already been taken")
    end

    it "使用者必須存在" do
      user_company = build(:user_company, user: nil)
      expect(user_company).not_to be_valid
      expect(user_company.errors[:user]).to include("must exist")
    end

    it "公司必須存在" do
      user_company = build(:user_company, company: nil)
      expect(user_company).not_to be_valid
      expect(user_company.errors[:company]).to include("must exist")
    end
  end

  describe "工廠" do
    it "可以建立有效的使用者公司關聯" do
      user_company = build(:user_company)
      expect(user_company).to be_valid
    end
  end
end