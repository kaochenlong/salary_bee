require 'rails_helper'

RSpec.describe User, type: :model do
  describe "validations" do
    it "需要 email_address" do
      user = build(:user, email_address: nil)
      expect(user).to_not be_valid
      expect(user.errors[:email_address]).to include("can't be blank")
    end

    it "email_address 必須唯一" do
      create(:user, email_address: "test@example.com")
      user = build(:user, email_address: "test@example.com")
      expect(user).to_not be_valid
      expect(user.errors[:email_address]).to include("has already been taken")
    end

    it "接受有效的 email 格式" do
      user = build(:user, email_address: "user@example.com")
      expect(user).to be_valid
    end

    it "正規化 email address" do
      user = create(:user, email_address: "  User@Example.COM  ")
      expect(user.email_address).to eq("user@example.com")
    end

    it "需要最小密碼長度" do
      user = build(:user, password: "123")
      expect(user).to_not be_valid
      expect(user.errors[:password]).to include("is too short (minimum is 6 characters)")
    end
  end

  describe "associations" do
    it "有多個 sessions" do
      user = create(:user)
      session1 = create(:session, user: user)
      session2 = create(:session, user: user)

      expect(user.sessions).to include(session1, session2)
    end

    it "刪除使用者時一併刪除 sessions" do
      user = create(:user)
      create(:session, user: user)

      expect { user.destroy }.to change { Session.count }.by(-1)
    end
  end

  describe "password authentication" do
    it "使用 has_secure_password" do
      user = create(:user, password: "password123")
      expect(user.authenticate("password123")).to eq(user)
      expect(user.authenticate("wrongpassword")).to be_falsey
    end
  end
end
