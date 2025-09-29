require 'rails_helper'

RSpec.describe DashboardController, type: :controller do
  let(:user) { create(:user) }

  describe "GET #index" do
    context "使用者已登入" do
      before { login_as(user) }

      it "回傳成功狀態" do
        get :index
        expect(response).to have_http_status(:success)
      end

      it "指派使用者的公司到 @companies" do
        company1 = create(:company)
        company2 = create(:company)
        create(:user_company, user: user, company: company1)
        create(:user_company, user: user, company: company2)

        get :index
        expect(assigns(:companies)).to match_array([ company1, company2 ])
      end

      it "不顯示其他使用者的公司" do
        other_user = create(:user)
        user_company = create(:company)
        other_company = create(:company)

        create(:user_company, user: user, company: user_company)
        create(:user_company, user: other_user, company: other_company)

        get :index
        expect(assigns(:companies)).to eq([ user_company ])
        expect(assigns(:companies)).not_to include(other_company)
      end

      it "渲染 index 模板" do
        get :index
        expect(response).to render_template(:index)
      end
    end

    context "使用者未登入" do
      it "重導向到登入頁面" do
        get :index
        expect(response).to redirect_to(new_session_path)
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