require 'rails_helper'

RSpec.describe "Registration System", type: :system do
  before do
    driven_by(:rack_test)
  end

  scenario "使用者成功註冊新帳號" do
    # 訪問註冊頁面
    visit new_user_path

    # 確認頁面內容
    expect(page).to have_content("SalaryBee")
    expect(page).to have_content("建立新帳號")

    # 填寫註冊表單
    fill_in "電子郵件", with: "newuser@example.com"
    fill_in "密碼", with: "password123"
    fill_in "確認密碼", with: "password123"
    click_button "建立帳號"

    # 確認重導向到登入頁面
    expect(current_path).to eq(new_session_path)
    expect(page).to have_content("帳號建立成功，請登入。")

    # 確認新使用者已建立
    user = User.find_by(email_address: "newuser@example.com")
    expect(user).to be_present
    expect(user.authenticate("password123")).to be_truthy

    # 確認沒有自動登入
    expect(page).not_to have_content("newuser@example.com")
    expect(page).to have_content("登入")
  end

  scenario "從 navbar 註冊連結進入註冊頁面" do
    visit root_path
    first("a", text: "註冊").click

    expect(current_path).to eq(new_user_path)
    expect(page).to have_content("建立新帳號")
  end

  scenario "註冊後可以用新帳號登入" do
    # 先註冊
    visit new_user_path
    fill_in "電子郵件", with: "test@example.com"
    fill_in "密碼", with: "password123"
    fill_in "確認密碼", with: "password123"
    click_button "建立帳號"

    # 確認在登入頁面
    expect(current_path).to eq(new_session_path)

    # 使用新帳號登入
    fill_in "電子郵件", with: "test@example.com"
    fill_in "密碼", with: "password123"
    click_button "登入 SalaryBee"

    # 確認登入成功
    expect(current_path).to eq(dashboard_path)
    expect(page).to have_content("test@example.com")
  end

  scenario "email 地址重複顯示錯誤" do
    existing_user = create(:user, email_address: "existing@example.com")

    visit new_user_path
    fill_in "電子郵件", with: "existing@example.com"
    fill_in "密碼", with: "password123"
    fill_in "確認密碼", with: "password123"
    click_button "建立帳號"

    # 確認停留在註冊頁面並顯示錯誤
    expect(current_path).to eq(users_path)
    expect(page).to have_content("請修正以下錯誤")
    expect(page).to have_content("has already been taken")
  end

  scenario "密碼確認不一致顯示錯誤" do
    visit new_user_path
    fill_in "電子郵件", with: "test@example.com"
    fill_in "密碼", with: "password123"
    fill_in "確認密碼", with: "different123"
    click_button "建立帳號"

    # 確認停留在註冊頁面並顯示錯誤
    expect(current_path).to eq(users_path)
    expect(page).to have_content("請修正以下錯誤")
    expect(page).to have_content("doesn't match Password")
  end

  scenario "密碼太短顯示錯誤" do
    visit new_user_path
    fill_in "電子郵件", with: "test@example.com"
    fill_in "密碼", with: "123"
    fill_in "確認密碼", with: "123"
    click_button "建立帳號"

    # 確認停留在註冊頁面並顯示錯誤
    expect(current_path).to eq(users_path)
    expect(page).to have_content("請修正以下錯誤")
    expect(page).to have_content("is too short")
  end

  scenario "email 格式不正確顯示錯誤" do
    visit new_user_path
    fill_in "電子郵件", with: "invalid-email"
    fill_in "密碼", with: "password123"
    fill_in "確認密碼", with: "password123"
    click_button "建立帳號"

    # 確認停留在註冊頁面並顯示錯誤
    expect(current_path).to eq(users_path)
    expect(page).to have_content("請修正以下錯誤")
  end

  scenario "空白欄位顯示錯誤" do
    visit new_user_path
    click_button "建立帳號"

    # 確認停留在註冊頁面並顯示錯誤
    expect(current_path).to eq(users_path)
    expect(page).to have_content("請修正以下錯誤")
  end

  scenario "註冊頁面有返回登入的連結" do
    visit new_user_path

    expect(page).to have_link("已有帳號？立即登入", href: new_session_path)
    click_link "已有帳號？立即登入"

    expect(current_path).to eq(new_session_path)
    expect(page).to have_content("登入")
  end
end