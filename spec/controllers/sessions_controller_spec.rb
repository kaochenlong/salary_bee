require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  describe "GET #new" do
    it "顯示登入表單" do
      get :new
      expect(response).to be_successful
      expect(response).to render_template(:new)
    end
  end

  describe "POST #create" do
    let(:user) { create(:user, password: "password123") }

    context "with valid credentials" do
      it "建立 session 並重導向" do
        post :create, params: {
          email_address: user.email_address,
          password: "password123"
        }
        expect(response).to redirect_to(root_url)
        expect(cookies.signed[:session_id]).to be_present
      end

      it "建立資料庫中的 session 記錄" do
        expect {
          post :create, params: {
            email_address: user.email_address,
            password: "password123"
          }
        }.to change { Session.count }.by(1)

        session = Session.last
        expect(session.user).to eq(user)
        expect(session.ip_address).to eq("0.0.0.0")
      end
    end

    context "with invalid credentials" do
      it "重導向到登入頁面並顯示錯誤" do
        post :create, params: {
          email_address: user.email_address,
          password: "wrongpass"
        }
        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq("Try another email address or password.")
      end

      it "不存在的 email" do
        post :create, params: {
          email_address: "nonexistent@example.com",
          password: "password123"
        }
        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq("Try another email address or password.")
      end
    end
  end

  describe "DELETE #destroy" do
    let(:user) { create(:user) }
    let(:user_session) { create(:session, user: user) }

    before do
      cookies.signed[:session_id] = user_session.id
      allow(Current).to receive(:session).and_return(user_session)
    end

    it "清除 session 並重導向" do
      delete :destroy
      expect(response).to redirect_to(new_session_path)
      expect(cookies[:session_id]).to be_nil
    end

    it "刪除資料庫中的 session" do
      expect { delete :destroy }.to change { Session.count }.by(-1)
    end
  end
end
