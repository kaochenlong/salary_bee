require 'rails_helper'

RSpec.describe Session, type: :model do
  describe "associations" do
    it "屬於一個 user" do
      user = create(:user)
      session = create(:session, user: user)

      expect(session.user).to eq(user)
    end

    it "需要 user" do
      session = build(:session, user: nil)
      expect(session).to_not be_valid
      expect(session.errors[:user]).to include("must exist")
    end
  end

  describe "attributes" do
    it "記錄 IP 地址" do
      session = create(:session, ip_address: "192.168.1.1")
      expect(session.ip_address).to eq("192.168.1.1")
    end

    it "記錄 user agent" do
      session = create(:session, user_agent: "Mozilla/5.0")
      expect(session.user_agent).to eq("Mozilla/5.0")
    end
  end
end
