require 'rails_helper'

RSpec.describe "Companies", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:company) { create(:company) }

  before { sign_in_as(user) }

  describe "GET /companies" do
    it "回傳成功狀態" do
      get companies_path
      expect(response).to have_http_status(:success)
    end

    it "顯示使用者的公司" do
      create(:user_company, user: user, company: company)
      get companies_path
      expect(response.body).to include(company.name)
    end
  end

  describe "GET /companies/:id" do
    context "使用者的公司" do
      before { create(:user_company, user: user, company: company) }

      it "回傳成功狀態" do
        get company_path(company)
        expect(response).to have_http_status(:success)
      end

      it "顯示公司詳細資訊" do
        get company_path(company)
        expect(response.body).to include(company.name)
        expect(response.body).to include(company.description)
      end
    end

    context "非使用者的公司" do
      let(:other_company) { create(:company) }

      it "回傳 404 狀態" do
        # 在測試環境中，我們需要設定讓 Rails 顯示例外狀況
        begin
          get company_path(other_company)
          # 如果到達這裡，表示沒有拋出例外，這是不對的
          expect(response).to have_http_status(:not_found)
        rescue ActiveRecord::RecordNotFound
          # 這是我們期望的結果
          expect(true).to be true
        end
      end
    end
  end

  describe "GET /companies/new" do
    it "回傳成功狀態" do
      get new_company_path
      expect(response).to have_http_status(:success)
    end

    it "顯示新增公司表單" do
      get new_company_path
      expect(response.body).to include("新增公司")
      expect(response.body).to include("form")
    end
  end

  describe "POST /companies" do
    context "有效參數" do
      let(:valid_params) do
        {
          company: {
            name: "新公司",
            description: "這是一家新公司"
          }
        }
      end

      it "建立新公司" do
        expect {
          post companies_path, params: valid_params
        }.to change(Company, :count).by(1)
      end

      it "建立使用者與公司的關聯" do
        expect {
          post companies_path, params: valid_params
        }.to change(user.companies, :count).by(1)
      end

      it "重導向到公司詳細頁面" do
        post companies_path, params: valid_params
        expect(response).to redirect_to(company_path(Company.last))
      end

      it "設定成功訊息" do
        post companies_path, params: valid_params
        follow_redirect!
        expect(response.body).to include("公司建立成功")
      end
    end

    context "無效參數" do
      let(:invalid_params) do
        {
          company: {
            name: "",
            description: "沒有名稱的公司"
          }
        }
      end

      it "不建立公司" do
        expect {
          post companies_path, params: invalid_params
        }.not_to change(Company, :count)
      end

      it "顯示錯誤訊息" do
        post companies_path, params: invalid_params
        expect(response.body).to include("請修正以下錯誤")
      end
    end
  end

  context "未認證使用者" do
    before { sign_out }

    it "重導向所有公司路由到登入頁面" do
      get companies_path
      expect(response).to redirect_to(new_session_path)

      get new_company_path
      expect(response).to redirect_to(new_session_path)

      post companies_path, params: { company: { name: "Test" } }
      expect(response).to redirect_to(new_session_path)
    end
  end

  private

  def sign_in_as(user)
    post session_path, params: {
      email_address: user.email_address,
      password: "password123"
    }
  end

  def sign_out
    delete session_path
  end
end