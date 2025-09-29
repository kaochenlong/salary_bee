require 'rails_helper'

RSpec.describe "Dashboard", type: :system do
  let(:user) { create(:user, password: "password123") }

  before do
    driven_by(:rack_test)
  end

  describe "使用者流程" do
    context "已登入使用者" do
      before { sign_in_as(user) }

      it "登入後看到 dashboard 頁面" do
        visit dashboard_path

        expect(page).to have_content("薪資管理儀表板")
        expect(page).to have_content("歡迎回來")
        expect(page).to have_content(user.email_address)
      end

      it "顯示使用者的公司列表" do
        company1 = create(:company, name: "軟體公司")
        company2 = create(:company, name: "顧問公司")
        create(:user_company, user: user, company: company1)
        create(:user_company, user: user, company: company2)

        visit dashboard_path

        expect(page).to have_content("我的公司")
        expect(page).to have_content("軟體公司")
        expect(page).to have_content("顧問公司")
        expect(page).to have_content("2 間公司")
      end

      it "顯示空狀態當沒有公司時" do
        visit dashboard_path

        expect(page).to have_content("還沒有公司資料")
        expect(page).to have_content("立即新增您的第一間公司")
      end

      it "可以點擊公司進入詳細頁面" do
        company = create(:company, name: "測試公司", description: "這是測試公司")
        create(:user_company, user: user, company: company)

        visit dashboard_path
        click_link "查看詳情"

        expect(page).to have_content("測試公司")
        expect(page).to have_content("這是測試公司")
        expect(current_path).to eq(company_path(company))
      end

      it "可以從 dashboard 新增公司" do
        visit dashboard_path
        first("a", text: "新增公司").click

        expect(current_path).to eq(new_company_path)
        expect(page).to have_content("新增公司")

        fill_in "公司名稱", with: "新創公司"
        fill_in "公司簡介", with: "這是一家新創公司"
        click_button "建立公司"

        expect(page).to have_content("公司建立成功")
        expect(page).to have_content("新創公司")

        # 確認回到 dashboard 後能看到新公司
        visit dashboard_path
        expect(page).to have_content("新創公司")
        expect(page).to have_content("1 間公司")
      end

      it "不顯示其他使用者的公司" do
        other_user = create(:user)
        user_company = create(:company, name: "我的公司")
        other_company = create(:company, name: "別人的公司")

        create(:user_company, user: user, company: user_company)
        create(:user_company, user: other_user, company: other_company)

        visit dashboard_path

        expect(page).to have_content("我的公司")
        expect(page).not_to have_content("別人的公司")
      end

      it "顯示正確的公司統計" do
        3.times do |i|
          company = create(:company, name: "公司 #{i + 1}")
          create(:user_company, user: user, company: company)
        end

        visit dashboard_path

        expect(page).to have_content("3 間公司")
      end
    end

    context "未登入使用者" do
      it "訪問 dashboard 時重導向到登入頁面" do
        visit dashboard_path

        expect(current_path).to eq(new_session_path)
        expect(page).to have_content("SalaryBee")
        expect(page).to have_content("登入")
      end

      it "登入後自動重導向到 dashboard" do
        visit dashboard_path

        # 應該被重導向到登入頁面
        expect(current_path).to eq(new_session_path)

        # 登入
        fill_in "電子郵件", with: user.email_address
        fill_in "密碼", with: "password123"
        click_button "登入 SalaryBee"

        # 應該自動回到 dashboard
        expect(current_path).to eq(dashboard_path)
        expect(page).to have_content("薪資管理儀表板")
      end
    end
  end

  private

  def sign_in_as(user)
    visit new_session_path
    fill_in "電子郵件", with: user.email_address
    fill_in "密碼", with: "password123"
    click_button "登入 SalaryBee"
  end
end