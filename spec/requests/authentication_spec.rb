require 'rails_helper'

RSpec.describe "Authentication", type: :request do
  describe "Session management" do
    let(:user) { create(:user, password: "password123") }

    describe "登入流程" do
      it "成功登入" do
        post session_path, params: {
          email_address: user.email_address,
          password: "password123"
        }

        expect(response).to redirect_to(dashboard_url)
        expect(response.cookies["session_id"]).to be_present
      end

      it "登入失敗" do
        post session_path, params: {
          email_address: user.email_address,
          password: "wrongpassword"
        }

        expect(response).to redirect_to(new_session_path)
        expect(response.cookies["session_id"]).to be_nil
      end
    end

    describe "登出流程" do
      before do
        post session_path, params: {
          email_address: user.email_address,
          password: "password123"
        }
      end

      it "成功登出" do
        delete session_path
        expect(response).to redirect_to(new_session_url)
        expect(response.cookies["session_id"]).to be_nil
      end
    end
  end

  describe "Password reset" do
    let(:user) { create(:user) }

    it "發送重設密碼的 email" do
      expect {
        post passwords_path, params: { email_address: user.email_address }
      }.to change { ActionMailer::Base.deliveries.count }.by(1)

      expect(response).to redirect_to(new_session_path)
      expect(flash[:notice]).to include("Password reset instructions sent")
    end

    it "不存在的 email 也返回成功訊息" do
      post passwords_path, params: { email_address: "nonexistent@example.com" }

      expect(response).to redirect_to(new_session_path)
      expect(flash[:notice]).to include("Password reset instructions sent")
      expect(ActionMailer::Base.deliveries.count).to eq(0)
    end
  end
end
