require 'rails_helper'

RSpec.describe "Users", type: :request do
  describe "GET /users/new" do
    it "回傳成功狀態" do
      get new_user_path
      expect(response).to have_http_status(:success)
    end

    it "顯示註冊表單" do
      get new_user_path
      expect(response.body).to include("建立新帳號")
      expect(response.body).to include("電子郵件")
      expect(response.body).to include("密碼")
      expect(response.body).to include("確認密碼")
    end

    it "包含正確的表單動作" do
      get new_user_path
      expect(response.body).to include('action="/users"')
      expect(response.body).to include('method="post"')
    end
  end

  describe "POST /users" do
    context "有效參數" do
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
          post users_path, params: valid_params
        }.to change(User, :count).by(1)
      end

      it "重導向到登入頁面" do
        post users_path, params: valid_params
        expect(response).to redirect_to(new_session_path)
      end

      it "設定成功訊息" do
        post users_path, params: valid_params
        follow_redirect!
        expect(response.body).to include("帳號建立成功，請登入。")
      end

      it "新使用者資料正確" do
        post users_path, params: valid_params
        user = User.last
        expect(user.email_address).to eq("newuser@example.com")
        expect(user.authenticate("password123")).to be_truthy
      end

      it "不自動建立 session" do
        post users_path, params: valid_params
        expect(response.cookies["session_id"]).to be_nil
      end
    end

    context "無效參數" do
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
          post users_path, params: invalid_params
        }.not_to change(User, :count)
      end

      it "回傳 422 狀態" do
        post users_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "顯示錯誤訊息" do
        post users_path, params: invalid_params
        expect(response.body).to include("請修正以下錯誤")
      end
    end

    context "重複的 email" do
      let!(:existing_user) { create(:user, email_address: "existing@example.com") }
      let(:duplicate_params) do
        {
          user: {
            email_address: "existing@example.com",
            password: "password123",
            password_confirmation: "password123"
          }
        }
      end

      it "不建立重複使用者" do
        expect {
          post users_path, params: duplicate_params
        }.not_to change(User, :count)
      end

      it "顯示 email 重複錯誤" do
        post users_path, params: duplicate_params
        expect(response.body).to include("has already been taken")
      end
    end

    context "密碼確認不一致" do
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
          post users_path, params: mismatch_params
        }.not_to change(User, :count)
      end

      it "顯示密碼確認錯誤" do
        post users_path, params: mismatch_params
        expect(response.body).to include("doesn&#39;t match Password")
      end
    end

    context "密碼太短" do
      let(:short_password_params) do
        {
          user: {
            email_address: "test@example.com",
            password: "123",
            password_confirmation: "123"
          }
        }
      end

      it "不建立使用者" do
        expect {
          post users_path, params: short_password_params
        }.not_to change(User, :count)
      end

      it "顯示密碼長度錯誤" do
        post users_path, params: short_password_params
        expect(response.body).to include("is too short")
      end
    end
  end
end