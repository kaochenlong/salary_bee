require 'rails_helper'

RSpec.describe CompaniesController, type: :controller do
  let(:user) { create(:user) }
  let(:company) { create(:company) }
  let(:user_company) { create(:user_company, user: user, company: company) }

  before { login_as(user) }

  describe "GET #index" do
    it "回傳成功狀態" do
      get :index
      expect(response).to have_http_status(:success)
    end

    it "指派使用者的公司到 @companies" do
      user_company
      other_company = create(:company)

      get :index
      expect(assigns(:companies)).to eq([ company ])
      expect(assigns(:companies)).not_to include(other_company)
    end
  end

  describe "GET #show" do
    context "使用者的公司" do
      before { user_company }

      it "回傳成功狀態" do
        get :show, params: { id: company.id }
        expect(response).to have_http_status(:success)
      end

      it "指派公司到 @company" do
        get :show, params: { id: company.id }
        expect(assigns(:company)).to eq(company)
      end
    end

    context "非使用者的公司" do
      let(:other_company) { create(:company) }

      it "拋出 ActiveRecord::RecordNotFound 錯誤" do
        expect {
          get :show, params: { id: other_company.id }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "GET #new" do
    it "回傳成功狀態" do
      get :new
      expect(response).to have_http_status(:success)
    end

    it "指派新公司到 @company" do
      get :new
      expect(assigns(:company)).to be_a_new(Company)
    end
  end

  describe "POST #create" do
    context "有效參數" do
      let(:valid_params) { { company: { name: "新公司", description: "公司描述", tax_id: "10458575" } } }

      it "建立新公司" do
        expect {
          post :create, params: valid_params
        }.to change(Company, :count).by(1)
      end

      it "建立使用者與公司的關聯" do
        expect {
          post :create, params: valid_params
        }.to change(UserCompany, :count).by(1)

        created_company = Company.last
        expect(user.companies).to include(created_company)
      end

      it "重導向到公司頁面" do
        post :create, params: valid_params
        expect(response).to redirect_to(Company.last)
      end
    end

    context "無效參數" do
      let(:invalid_params) { { company: { name: "", description: "公司描述", tax_id: "" } } }

      it "不建立公司" do
        expect {
          post :create, params: invalid_params
        }.not_to change(Company, :count)
      end

      it "重新渲染 new 模板" do
        post :create, params: invalid_params
        expect(response).to render_template(:new)
      end
    end
  end

  private

  def login_as(user)
    session = create(:session, user: user)
    Current.session = session
    allow(controller).to receive(:find_session_by_cookie).and_return(session)
  end
end