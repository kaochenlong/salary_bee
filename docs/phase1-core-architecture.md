# 階段一：核心架構建立

## 概述

建立薪資管理系統的核心多租戶架構，讓會計師能夠管理多家公司的薪資業務。

## 目標

- 建立多租戶資料模型
- 實作公司切換機制
- 設置基本權限控制
- 建立系統基礎架構

## 資料模型設計

### 核心實體關係

```
Accountant (會計師)
├── has_many :company_accountants
├── has_many :companies, through: :company_accountants
└── 權限：管理指定公司的所有薪資資料

Company (公司)
├── has_many :company_accountants
├── has_many :accountants, through: :company_accountants
├── has_many :employees
└── 屬性：公司基本資料、薪資政策設定

CompanyAccountant (會計師-公司關聯)
├── belongs_to :accountant
├── belongs_to :company
└── 屬性：權限等級、建立時間

Employee (員工)
├── belongs_to :company
└── 屬性：基本資料、薪資結構
```

### 資料庫遷移

```ruby
# 001_create_accountants.rb
class CreateAccountants < ActiveRecord::Migration[7.0]
  def change
    create_table :accountants do |t|
      t.string :name, null: false
      t.string :email, null: false, index: { unique: true }
      t.string :phone
      t.string :license_number # 會計師證照號碼

      t.timestamps
    end
  end
end

# 002_create_companies.rb
class CreateCompanies < ActiveRecord::Migration[7.0]
  def change
    create_table :companies do |t|
      t.string :name, null: false
      t.string :tax_id, null: false, index: { unique: true }
      t.string :address
      t.string :phone
      t.string :contact_person
      t.integer :employee_count, default: 0

      # 薪資政策設定
      t.json :payroll_settings, default: {}

      t.timestamps
    end
  end
end

# 003_create_company_accountants.rb
class CreateCompanyAccountants < ActiveRecord::Migration[7.0]
  def change
    create_table :company_accountants do |t|
      t.references :accountant, null: false, foreign_key: true
      t.references :company, null: false, foreign_key: true
      t.string :role, default: 'manager' # manager, viewer
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :company_accountants, [:accountant_id, :company_id], unique: true
  end
end

# 004_create_employees.rb
class CreateEmployees < ActiveRecord::Migration[7.0]
  def change
    create_table :employees do |t|
      t.references :company, null: false, foreign_key: true

      # 基本資料
      t.string :employee_id, null: false
      t.string :name, null: false
      t.string :id_number # 身分證字號
      t.string :email
      t.string :phone
      t.date :birth_date
      t.date :hire_date
      t.date :resign_date
      t.string :department
      t.string :position

      # 薪資結構
      t.decimal :base_salary, precision: 10, scale: 2, default: 0
      t.json :allowances, default: {} # 各種津貼
      t.json :deductions, default: {} # 各種扣款

      # 勞健保資料
      t.string :labor_insurance_group
      t.string :health_insurance_group

      t.boolean :active, default: true
      t.timestamps
    end

    add_index :employees, [:company_id, :employee_id], unique: true
  end
end
```

## Model 實作

### Accountant Model

```ruby
# app/models/accountant.rb
class Accountant < ApplicationRecord
  has_many :company_accountants, dependent: :destroy
  has_many :companies, through: :company_accountants

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :license_number, presence: true, uniqueness: true

  def managed_companies
    companies.joins(:company_accountants)
             .where(company_accountants: { active: true })
  end

  def can_access_company?(company)
    company_accountants.active.exists?(company: company)
  end
end
```

### Company Model

```ruby
# app/models/company.rb
class Company < ApplicationRecord
  has_many :company_accountants, dependent: :destroy
  has_many :accountants, through: :company_accountants
  has_many :employees, dependent: :destroy

  validates :name, presence: true
  validates :tax_id, presence: true, uniqueness: true

  before_save :update_employee_count

  def active_employees
    employees.where(active: true)
  end

  def payroll_setting(key)
    payroll_settings[key.to_s]
  end

  def set_payroll_setting(key, value)
    self.payroll_settings = payroll_settings.merge(key.to_s => value)
  end

  private

  def update_employee_count
    self.employee_count = active_employees.count
  end
end
```

### Employee Model

```ruby
# app/models/employee.rb
class Employee < ApplicationRecord
  belongs_to :company

  validates :employee_id, presence: true, uniqueness: { scope: :company_id }
  validates :name, presence: true
  validates :hire_date, presence: true
  validates :base_salary, presence: true, numericality: { greater_than: 0 }

  scope :active, -> { where(active: true) }
  scope :by_department, ->(dept) { where(department: dept) }

  def full_name_with_id
    "#{name} (#{employee_id})"
  end

  def total_allowances
    allowances.values.sum
  end

  def total_deductions
    deductions.values.sum
  end

  def gross_salary
    base_salary + total_allowances
  end
end
```

## 公司切換機制

### Application Controller 基礎

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :authenticate_accountant
  before_action :set_current_company

  private

  def authenticate_accountant
    # 實作會計師認證邏輯
    @current_accountant ||= Accountant.find(session[:accountant_id]) if session[:accountant_id]
    redirect_to login_path unless @current_accountant
  end

  def set_current_company
    return unless @current_accountant

    company_id = params[:company_id] || session[:current_company_id]

    if company_id
      @current_company = @current_accountant.managed_companies.find_by(id: company_id)
      session[:current_company_id] = @current_company&.id
    end

    @current_company ||= @current_accountant.managed_companies.first
    session[:current_company_id] = @current_company&.id
  end

  def require_company
    redirect_to companies_path, alert: '請選擇要管理的公司' unless @current_company
  end
end
```

### Companies Controller

```ruby
# app/controllers/companies_controller.rb
class CompaniesController < ApplicationController
  def index
    @companies = @current_accountant.managed_companies.order(:name)
  end

  def switch
    company = @current_accountant.managed_companies.find(params[:id])
    session[:current_company_id] = company.id
    redirect_to root_path, notice: "已切換至 #{company.name}"
  rescue ActiveRecord::RecordNotFound
    redirect_to companies_path, alert: '無權限存取該公司'
  end

  def show
    @company = @current_company
    redirect_to companies_path unless @company
  end
end
```

## 權限控制系統

### 權限檢查方法

```ruby
# app/controllers/concerns/company_authorization.rb
module CompanyAuthorization
  extend ActiveSupport::Concern

  included do
    before_action :authorize_company_access
  end

  private

  def authorize_company_access
    unless @current_accountant.can_access_company?(@current_company)
      redirect_to companies_path, alert: '無權限存取該公司資料'
    end
  end

  def authorize_company_management
    company_accountant = @current_accountant.company_accountants
                                            .find_by(company: @current_company)

    unless company_accountant&.role == 'manager'
      redirect_to root_path, alert: '無管理權限'
    end
  end
end
```

## 路由設計

```ruby
# config/routes.rb
Rails.application.routes.draw do
  root 'dashboard#index'

  # 認證相關
  get 'login', to: 'sessions#new'
  post 'login', to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy'

  # 公司選擇和切換
  resources :companies, only: [:index, :show] do
    member do
      patch :switch
    end

    # 在公司 scope 下的資源
    resources :employees
    resources :payrolls
    # ... 其他與公司相關的資源
  end
end
```

## 前端公司切換器

### 公司選擇器 Partial

```erb
<!-- app/views/shared/_company_selector.html.erb -->
<div class="navbar bg-base-100 border-b">
  <div class="flex-1">
    <% if @current_company %>
      <div class="dropdown">
        <div tabindex="0" role="button" class="btn btn-ghost normal-case text-xl">
          <%= @current_company.name %>
          <svg class="fill-current" xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24">
            <path d="M7.41,8.58L12,13.17L16.59,8.58L18,10L12,16L6,10L7.41,8.58Z"/>
          </svg>
        </div>
        <ul tabindex="0" class="dropdown-content z-[1] menu p-2 shadow bg-base-100 rounded-box w-64">
          <% @current_accountant.managed_companies.each do |company| %>
            <li>
              <%= link_to switch_company_path(company), method: :patch,
                          class: (@current_company == company ? "active" : "") do %>
                <div class="flex flex-col items-start">
                  <span class="font-medium"><%= company.name %></span>
                  <span class="text-sm opacity-60"><%= company.tax_id %></span>
                </div>
              <% end %>
            </li>
          <% end %>
        </ul>
      </div>
    <% else %>
      <%= link_to "選擇公司", companies_path, class: "btn btn-primary" %>
    <% end %>
  </div>

  <div class="flex-none">
    <div class="dropdown dropdown-end">
      <div tabindex="0" role="button" class="btn btn-ghost btn-circle avatar">
        <div class="w-10 rounded-full bg-primary text-primary-content flex items-center justify-center">
          <%= @current_accountant.name.first %>
        </div>
      </div>
      <ul tabindex="0" class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-base-100 rounded-box w-52">
        <li><%= link_to "登出", logout_path, method: :delete %></li>
      </ul>
    </div>
  </div>
</div>
```

## 測試計劃

### Model 測試

```ruby
# spec/models/accountant_spec.rb
RSpec.describe Accountant, type: :model do
  describe 'associations' do
    it { should have_many(:company_accountants) }
    it { should have_many(:companies).through(:company_accountants) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email) }
  end

  describe '#can_access_company?' do
    it 'returns true for managed companies' do
      # 測試邏輯
    end
  end
end
```

### Controller 測試

```ruby
# spec/controllers/companies_controller_spec.rb
RSpec.describe CompaniesController, type: :controller do
  describe 'GET #switch' do
    it 'switches to selected company' do
      # 測試公司切換邏輯
    end

    it 'denies access to unauthorized company' do
      # 測試權限控制
    end
  end
end
```

## 部署注意事項

### 環境變數設定

```env
# .env
DATABASE_URL=postgresql://username:password@localhost/salarybee_development
SECRET_KEY_BASE=your_secret_key_here
```

### 資料庫索引優化

```ruby
# 為頻繁查詢的欄位添加索引
add_index :employees, [:company_id, :active]
add_index :company_accountants, [:accountant_id, :active]
```

## 完成標準

- [ ] 資料庫遷移檔案建立並執行成功
- [ ] 所有 Model 實作完成並通過測試
- [ ] 公司切換功能正常運作
- [ ] 權限控制機制有效
- [ ] 基本路由設定完成
- [ ] 前端公司選擇器可正常使用

## 下一階段準備

完成核心架構後，階段二將基於這個架構建立員工管理功能。