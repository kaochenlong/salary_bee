require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  describe "GET #new" do
    it "顯示註冊表單" do
      get :new
      expect(response).to be_successful
      expect(response).to render_template(:new)
      expect(assigns(:user)).to be_a_new(User)
    end
  end

  describe "POST #create" do
    context "with valid parameters" do
      let(:valid_params) do
        {
          user: {
            email_address: "newuser@example.com",
            password: "password123",
            password_confirmation: "password123"
          }
        }
      end

      it "建立新使用者" do
        expect {
          post :create, params: valid_params
        }.to change(User, :count).by(1)
      end

      it "重導向到登入頁面" do
        post :create, params: valid_params
        expect(response).to redirect_to(new_session_path)
      end

      it "設定成功訊息" do
        post :create, params: valid_params
        expect(flash[:notice]).to eq("帳號建立成功，請登入。")
      end

      it "不自動登入使用者" do
        post :create, params: valid_params
        expect(cookies.signed[:session_id]).to be_nil
        expect(Current.session).to be_nil
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          user: {
            email_address: "",
            password: "short",
            password_confirmation: "different"
          }
        }
      end

      it "不建立使用者" do
        expect {
          post :create, params: invalid_params
        }.not_to change(User, :count)
      end

      it "顯示錯誤並重新顯示表單" do
        post :create, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:new)
      end

      it "顯示驗證錯誤訊息" do
        post :create, params: invalid_params
        expect(assigns(:user).errors).not_to be_empty
      end
    end

    context "with duplicate email" do
      let!(:existing_user) { create(:user, email_address: "test@example.com") }
      let(:duplicate_params) do
        {
          user: {
            email_address: "test@example.com",
            password: "password123",
            password_confirmation: "password123"
          }
        }
      end

      it "不建立重複使用者" do
        expect {
          post :create, params: duplicate_params
        }.not_to change(User, :count)
      end

      it "顯示 email 重複錯誤" do
        post :create, params: duplicate_params
        expect(assigns(:user).errors[:email_address]).to include("has already been taken")
      end
    end

    context "with mismatched password confirmation" do
      let(:mismatch_params) do
        {
          user: {
            email_address: "test@example.com",
            password: "password123",
            password_confirmation: "different123"
          }
        }
      end

      it "不建立使用者" do
        expect {
          post :create, params: mismatch_params
        }.not_to change(User, :count)
      end

      it "顯示密碼確認錯誤" do
        post :create, params: mismatch_params
        expect(assigns(:user).errors[:password_confirmation]).to include("doesn't match Password")
      end
    end
  end
end