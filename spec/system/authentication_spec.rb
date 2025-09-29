require 'rails_helper'

RSpec.describe "Authentication System", type: :system do
  before do
    driven_by(:rack_test)
  end

  scenario "使用者登入和登出" do
    user = create(:user, email_address: "user@example.com", password: "password123")

    # 訪問登入頁面
    visit new_session_path

    # 填寫登入表單
    fill_in "電子郵件", with: "user@example.com"
    fill_in "密碼", with: "password123"
    click_button "登入 SalaryBee"

    # 確認登入成功
    expect(current_path).to eq(dashboard_path)
    expect(page).to have_content("user@example.com")

    # 登出
    find("input[type='submit'][value='登出']").click

    # 確認登出成功
    expect(current_path).to eq(new_session_path)
  end

  scenario "使用者要求重設密碼" do
    user = create(:user, email_address: "user@example.com")

    # 訪問密碼重設頁面
    visit new_password_path

    # 填寫 email
    fill_in "電子郵件地址", with: "user@example.com"
    click_button "發送重設指示"

    # 確認重導向到登入頁面
    expect(current_path).to eq(new_session_path)

    # 確認發送了 email
    expect(ActionMailer::Base.deliveries.count).to eq(1)
  end

  scenario "登入失敗顯示錯誤訊息" do
    user = create(:user, email_address: "user@example.com", password: "password123")

    visit new_session_path

    # 輸入錯誤密碼
    fill_in "電子郵件", with: "user@example.com"
    fill_in "密碼", with: "wrongpassword"
    click_button "登入 SalaryBee"

    # 確認停留在登入頁面
    expect(current_path).to eq(new_session_path)
    expect(page).to have_content("Try another email address or password")
  end

  scenario "flash 訊息使用統一樣式" do
    user = create(:user, email_address: "user@example.com", password: "password123")

    visit new_session_path

    # 輸入錯誤密碼觸發 alert
    fill_in "電子郵件", with: "user@example.com"
    fill_in "密碼", with: "wrongpassword"
    click_button "登入 SalaryBee"

    # 確認 flash 訊息有正確的 CSS classes (在重構後會生效)
    # 這個測試在重構前會失敗，重構後應該通過
    within('[class*="text-red-600"]') do
      expect(page).to have_content("Try another email address or password")
    end
  end
end
