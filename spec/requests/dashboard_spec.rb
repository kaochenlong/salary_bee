require 'rails_helper'

RSpec.describe "Dashboard", type: :request do
  let(:user) { create(:user, password: "password123") }

  describe "GET /dashboard" do
    context "已認證使用者" do
      before { sign_in_as(user) }

      it "回傳成功狀態" do
        get dashboard_path
        expect(response).to have_http_status(:success)
      end

      it "顯示 dashboard 頁面" do
        get dashboard_path
        expect(response.body).to include("儀表板")
      end

      it "顯示使用者的公司" do
        company = create(:company, name: "測試公司")
        create(:user_company, user: user, company: company)

        get dashboard_path
        expect(response.body).to include("測試公司")
      end

      it "不顯示其他使用者的公司" do
        other_user = create(:user)
        other_company = create(:company, name: "其他公司")
        create(:user_company, user: other_user, company: other_company)

        get dashboard_path
        expect(response.body).not_to include("其他公司")
      end
    end

    context "未認證使用者" do
      it "重導向到登入頁面" do
        get dashboard_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  private

  def sign_in_as(user)
    post session_path, params: {
      email_address: user.email_address,
      password: "password123"
    }
  end
end