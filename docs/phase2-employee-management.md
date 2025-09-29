# 階段二：員工管理功能

## 概述

基於階段一建立的核心架構，實作完整的員工管理功能，包括 CRUD 操作、資料匯入匯出、薪資結構設定等。

## 目標

- 建立員工資料的完整 CRUD 功能
- 實作批量匯入/匯出機制
- 設計薪資結構設定介面
- 建立搜尋和篩選功能
- 實作資料驗證和錯誤處理

## 功能需求

### 1. 員工基本資料管理

#### 新增員工
- 基本資料輸入（姓名、身分證、聯絡方式等）
- 職務資料設定（部門、職位、到職日期）
- 薪資結構設定（底薪、津貼、扣款項目）
- 勞健保資料設定

#### 編輯員工
- 所有基本資料可編輯
- 薪資調整紀錄追蹤
- 職位異動紀錄

#### 刪除/停用員工
- 軟刪除機制（設為非活躍狀態）
- 保留歷史薪資資料
- 離職日期設定

### 2. 批量操作功能

#### 批量匯入
- Excel 格式範本下載
- CSV 格式支援
- 資料驗證和錯誤回報
- 匯入預覽功能

#### 批量匯出
- 員工清單匯出
- 薪資結構匯出
- 自訂欄位選擇

#### 批量編輯
- 薪資調整
- 部門異動
- 勞健保級距調整

## Controller 實作

### Employees Controller

```ruby
# app/controllers/employees_controller.rb
class EmployeesController < ApplicationController
  include CompanyAuthorization

  before_action :require_company
  before_action :set_employee, only: [:show, :edit, :update, :destroy, :activate]

  def index
    @pagy, @employees = pagy(filtered_employees.includes(:company),
                            items: params[:per_page] || 20)

    respond_to do |format|
      format.html
      format.csv { export_csv }
      format.xlsx { export_xlsx }
    end
  end

  def show
    @salary_history = @employee.salary_histories.order(effective_date: :desc)
  end

  def new
    @employee = @current_company.employees.build
    set_form_data
  end

  def create
    @employee = @current_company.employees.build(employee_params)

    if @employee.save
      create_salary_history
      redirect_to [@current_company, @employee],
                  notice: '員工資料已成功建立'
    else
      set_form_data
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    set_form_data
  end

  def update
    old_salary = @employee.base_salary

    if @employee.update(employee_params)
      create_salary_history if salary_changed?(old_salary)
      redirect_to [@current_company, @employee],
                  notice: '員工資料已更新'
    else
      set_form_data
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @employee.update(active: false, resign_date: Date.current)
    redirect_to company_employees_path(@current_company),
                notice: '員工已設為離職狀態'
  end

  def activate
    @employee.update(active: true, resign_date: nil)
    redirect_to company_employees_path(@current_company),
                notice: '員工已重新啟用'
  end

  def bulk_import
    redirect_to company_employees_path(@current_company) unless request.post?

    if params[:file].present?
      result = EmployeeImportService.new(@current_company, params[:file]).call

      if result.success?
        redirect_to company_employees_path(@current_company),
                    notice: "成功匯入 #{result.imported_count} 位員工"
      else
        @import_errors = result.errors
        render :index
      end
    end
  end

  def download_template
    send_file Rails.root.join('app', 'assets', 'templates', 'employee_import_template.xlsx'),
              filename: '員工資料匯入範本.xlsx',
              type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  end

  private

  def set_employee
    @employee = @current_company.employees.find(params[:id])
  end

  def filtered_employees
    employees = @current_company.employees
    employees = employees.where(active: true) unless params[:show_all]
    employees = employees.where('name ILIKE ?', "%#{params[:search]}%") if params[:search].present?
    employees = employees.where(department: params[:department]) if params[:department].present?
    employees.order(:name)
  end

  def employee_params
    params.require(:employee).permit(
      :employee_id, :name, :id_number, :email, :phone, :birth_date,
      :hire_date, :resign_date, :department, :position, :base_salary,
      :labor_insurance_group, :health_insurance_group,
      allowances: {}, deductions: {}
    )
  end

  def set_form_data
    @departments = @current_company.employees.distinct.pluck(:department).compact
    @positions = @current_company.employees.distinct.pluck(:position).compact
  end

  def salary_changed?(old_salary)
    @employee.base_salary != old_salary
  end

  def create_salary_history
    @employee.salary_histories.create!(
      effective_date: @employee.hire_date || Date.current,
      base_salary: @employee.base_salary,
      allowances: @employee.allowances,
      deductions: @employee.deductions,
      reason: @employee.persisted? ? '薪資調整' : '到職設定'
    )
  end

  def export_csv
    csv_data = EmployeeExportService.new(@current_company.employees, :csv).call
    send_data csv_data,
              filename: "#{@current_company.name}_員工清單_#{Date.current}.csv",
              type: 'text/csv'
  end

  def export_xlsx
    xlsx_data = EmployeeExportService.new(@current_company.employees, :xlsx).call
    send_data xlsx_data,
              filename: "#{@current_company.name}_員工清單_#{Date.current}.xlsx",
              type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  end
end
```

## Service 類別實作

### Employee Import Service

```ruby
# app/services/employee_import_service.rb
class EmployeeImportService
  include ActiveModel::Model

  attr_reader :company, :file, :imported_count, :errors

  def initialize(company, file)
    @company = company
    @file = file
    @imported_count = 0
    @errors = []
  end

  def call
    return failure('請選擇檔案') unless file.present?
    return failure('檔案格式不支援') unless valid_file_format?

    process_file
    success?
  end

  def success?
    errors.empty?
  end

  private

  def valid_file_format?
    %w[.csv .xlsx .xls].include?(File.extname(file.original_filename))
  end

  def process_file
    rows = parse_file

    ActiveRecord::Base.transaction do
      rows.each_with_index do |row, index|
        process_row(row, index + 2) # +2 because index starts at 0 and header is row 1
      end
    end
  rescue ActiveRecord::Rollback
    # Transaction was rolled back due to errors
  end

  def parse_file
    case File.extname(file.original_filename)
    when '.csv'
      parse_csv
    when '.xlsx', '.xls'
      parse_excel
    end
  end

  def parse_csv
    require 'csv'
    CSV.parse(file.read, headers: true, encoding: 'UTF-8')
  end

  def parse_excel
    require 'roo'
    excel = Roo::Spreadsheet.open(file.tempfile)
    excel.parse(headers: true)
  end

  def process_row(row, row_number)
    employee_data = map_row_to_attributes(row)

    if valid_row_data?(employee_data, row_number)
      employee = company.employees.build(employee_data)

      if employee.save
        @imported_count += 1
      else
        add_error(row_number, employee.errors.full_messages.join(', '))
        raise ActiveRecord::Rollback
      end
    else
      raise ActiveRecord::Rollback
    end
  end

  def map_row_to_attributes(row)
    {
      employee_id: row['員工編號']&.to_s&.strip,
      name: row['姓名']&.strip,
      id_number: row['身分證字號']&.strip,
      email: row['Email']&.strip,
      phone: row['電話']&.strip,
      birth_date: parse_date(row['生日']),
      hire_date: parse_date(row['到職日期']),
      department: row['部門']&.strip,
      position: row['職位']&.strip,
      base_salary: parse_decimal(row['底薪']),
      allowances: parse_json_field(row['津貼（JSON格式）']),
      deductions: parse_json_field(row['扣款（JSON格式）'])
    }.compact
  end

  def valid_row_data?(data, row_number)
    required_fields = [:employee_id, :name, :hire_date, :base_salary]
    missing_fields = required_fields.select { |field| data[field].blank? }

    if missing_fields.any?
      add_error(row_number, "缺少必填欄位: #{missing_fields.join(', ')}")
      return false
    end

    # 檢查員工編號是否重複
    if company.employees.exists?(employee_id: data[:employee_id])
      add_error(row_number, "員工編號 #{data[:employee_id]} 已存在")
      return false
    end

    true
  end

  def parse_date(date_string)
    return nil if date_string.blank?
    Date.parse(date_string.to_s) rescue nil
  end

  def parse_decimal(decimal_string)
    return nil if decimal_string.blank?
    decimal_string.to_s.gsub(/[,\s]/, '').to_f
  end

  def parse_json_field(json_string)
    return {} if json_string.blank?
    JSON.parse(json_string) rescue {}
  end

  def add_error(row_number, message)
    @errors << "第 #{row_number} 行: #{message}"
  end

  def failure(message)
    @errors << message
    OpenStruct.new(success?: false, errors: errors)
  end
end
```

### Employee Export Service

```ruby
# app/services/employee_export_service.rb
class EmployeeExportService
  def initialize(employees, format = :csv)
    @employees = employees.includes(:company)
    @format = format
  end

  def call
    case @format
    when :csv
      generate_csv
    when :xlsx
      generate_xlsx
    end
  end

  private

  def generate_csv
    require 'csv'

    CSV.generate(headers: true) do |csv|
      csv << csv_headers

      @employees.each do |employee|
        csv << csv_row_data(employee)
      end
    end
  end

  def generate_xlsx
    require 'rubyXL'

    workbook = RubyXL::Workbook.new
    worksheet = workbook[0]
    worksheet.sheet_name = '員工清單'

    # 添加標題行
    csv_headers.each_with_index do |header, index|
      worksheet.add_cell(0, index, header)
    end

    # 添加資料行
    @employees.each_with_index do |employee, row_index|
      csv_row_data(employee).each_with_index do |value, col_index|
        worksheet.add_cell(row_index + 1, col_index, value)
      end
    end

    workbook.stream.string
  end

  def csv_headers
    [
      '公司名稱', '員工編號', '姓名', '身分證字號', 'Email', '電話',
      '生日', '到職日期', '離職日期', '部門', '職位', '底薪',
      '津貼總額', '扣款總額', '毛薪', '狀態'
    ]
  end

  def csv_row_data(employee)
    [
      employee.company.name,
      employee.employee_id,
      employee.name,
      employee.id_number,
      employee.email,
      employee.phone,
      employee.birth_date,
      employee.hire_date,
      employee.resign_date,
      employee.department,
      employee.position,
      employee.base_salary,
      employee.total_allowances,
      employee.total_deductions,
      employee.gross_salary,
      employee.active? ? '在職' : '離職'
    ]
  end
end
```

## 前端 View 實作

### 員工清單頁面

```erb
<!-- app/views/employees/index.html.erb -->
<div class="container mx-auto px-4 py-6">
  <!-- 頁面標題和操作按鈕 -->
  <div class="flex justify-between items-center mb-6">
    <div>
      <h1 class="text-3xl font-bold">員工管理</h1>
      <p class="text-gray-600"><%= @current_company.name %></p>
    </div>

    <div class="flex gap-3">
      <%= link_to "匯入員工", bulk_import_company_employees_path(@current_company),
                  class: "btn btn-secondary" %>
      <%= link_to "下載範本", download_template_company_employees_path(@current_company),
                  class: "btn btn-outline" %>
      <%= link_to "新增員工", new_company_employee_path(@current_company),
                  class: "btn btn-primary" %>
    </div>
  </div>

  <!-- 搜尋和篩選 -->
  <%= form_with url: company_employees_path(@current_company), method: :get,
                local: true, class: "card bg-base-100 shadow-sm mb-6" do |f| %>
    <div class="card-body">
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div class="form-control">
          <%= f.text_field :search, placeholder: "搜尋員工姓名",
                          value: params[:search],
                          class: "input input-bordered" %>
        </div>

        <div class="form-control">
          <%= f.select :department,
                      options_for_select([['所有部門', '']] +
                        @current_company.employees.distinct.pluck(:department).compact.map { |d| [d, d] },
                        params[:department]),
                      {}, { class: "select select-bordered" } %>
        </div>

        <div class="form-control">
          <label class="label cursor-pointer">
            <%= f.check_box :show_all, { checked: params[:show_all] },
                           "1", "" %>
            <span class="label-text">顯示離職員工</span>
          </label>
        </div>

        <div class="form-control">
          <%= f.submit "搜尋", class: "btn btn-primary" %>
        </div>
      </div>
    </div>
  <% end %>

  <!-- 匯出選項 -->
  <div class="flex justify-end mb-4 gap-2">
    <%= link_to "匯出 CSV", company_employees_path(@current_company, format: :csv, **request.query_parameters),
                class: "btn btn-sm btn-outline" %>
    <%= link_to "匯出 Excel", company_employees_path(@current_company, format: :xlsx, **request.query_parameters),
                class: "btn btn-sm btn-outline" %>
  </div>

  <!-- 員工列表 -->
  <div class="card bg-base-100 shadow-sm">
    <div class="card-body p-0">
      <div class="overflow-x-auto">
        <table class="table table-zebra">
          <thead>
            <tr>
              <th>員工編號</th>
              <th>姓名</th>
              <th>部門</th>
              <th>職位</th>
              <th>到職日期</th>
              <th>底薪</th>
              <th>狀態</th>
              <th>操作</th>
            </tr>
          </thead>
          <tbody>
            <% @employees.each do |employee| %>
              <tr class="<%= 'opacity-50' unless employee.active? %>">
                <td><%= employee.employee_id %></td>
                <td>
                  <%= link_to company_employee_path(@current_company, employee),
                              class: "link link-primary font-medium" do %>
                    <%= employee.name %>
                  <% end %>
                </td>
                <td><%= employee.department %></td>
                <td><%= employee.position %></td>
                <td><%= employee.hire_date.strftime('%Y/%m/%d') if employee.hire_date %></td>
                <td class="text-right"><%= number_to_currency(employee.base_salary, unit: 'NT$ ') %></td>
                <td>
                  <% if employee.active? %>
                    <span class="badge badge-success">在職</span>
                  <% else %>
                    <span class="badge badge-error">離職</span>
                  <% end %>
                </td>
                <td>
                  <div class="flex gap-1">
                    <%= link_to "編輯", edit_company_employee_path(@current_company, employee),
                                class: "btn btn-xs btn-primary" %>
                    <% if employee.active? %>
                      <%= link_to "停用", company_employee_path(@current_company, employee),
                                  method: :delete,
                                  class: "btn btn-xs btn-error",
                                  confirm: "確定要將 #{employee.name} 設為離職嗎？" %>
                    <% else %>
                      <%= link_to "啟用", activate_company_employee_path(@current_company, employee),
                                  method: :patch,
                                  class: "btn btn-xs btn-success" %>
                    <% end %>
                  </div>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
  </div>

  <!-- 分頁 -->
  <div class="flex justify-center mt-6">
    <%== pagy_nav(@pagy) if @pagy.pages > 1 %>
  </div>
</div>
```

### 員工表單頁面

```erb
<!-- app/views/employees/_form.html.erb -->
<%= form_with model: [@current_company, @employee], local: true,
              class: "space-y-6" do |f| %>

  <% if @employee.errors.any? %>
    <div class="alert alert-error">
      <div>
        <h3 class="font-bold">資料驗證錯誤：</h3>
        <ul class="list-disc list-inside">
          <% @employee.errors.full_messages.each do |message| %>
            <li><%= message %></li>
          <% end %>
        </ul>
      </div>
    </div>
  <% end %>

  <!-- 基本資料 -->
  <div class="card bg-base-100 shadow-sm">
    <div class="card-body">
      <h2 class="card-title mb-4">基本資料</h2>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div class="form-control">
          <%= f.label :employee_id, "員工編號", class: "label" %>
          <%= f.text_field :employee_id,
                          class: "input input-bordered #{'input-error' if @employee.errors[:employee_id].any?}" %>
        </div>

        <div class="form-control">
          <%= f.label :name, "姓名", class: "label" %>
          <%= f.text_field :name,
                          class: "input input-bordered #{'input-error' if @employee.errors[:name].any?}" %>
        </div>

        <div class="form-control">
          <%= f.label :id_number, "身分證字號", class: "label" %>
          <%= f.text_field :id_number,
                          class: "input input-bordered #{'input-error' if @employee.errors[:id_number].any?}" %>
        </div>

        <div class="form-control">
          <%= f.label :email, "Email", class: "label" %>
          <%= f.email_field :email,
                           class: "input input-bordered #{'input-error' if @employee.errors[:email].any?}" %>
        </div>

        <div class="form-control">
          <%= f.label :phone, "電話", class: "label" %>
          <%= f.telephone_field :phone,
                               class: "input input-bordered #{'input-error' if @employee.errors[:phone].any?}" %>
        </div>

        <div class="form-control">
          <%= f.label :birth_date, "生日", class: "label" %>
          <%= f.date_field :birth_date,
                          class: "input input-bordered #{'input-error' if @employee.errors[:birth_date].any?}" %>
        </div>
      </div>
    </div>
  </div>

  <!-- 職務資料 -->
  <div class="card bg-base-100 shadow-sm">
    <div class="card-body">
      <h2 class="card-title mb-4">職務資料</h2>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div class="form-control">
          <%= f.label :department, "部門", class: "label" %>
          <%= f.text_field :department,
                          list: "departments",
                          class: "input input-bordered #{'input-error' if @employee.errors[:department].any?}" %>
          <datalist id="departments">
            <% @departments.each do |dept| %>
              <option value="<%= dept %>">
            <% end %>
          </datalist>
        </div>

        <div class="form-control">
          <%= f.label :position, "職位", class: "label" %>
          <%= f.text_field :position,
                          list: "positions",
                          class: "input input-bordered #{'input-error' if @employee.errors[:position].any?}" %>
          <datalist id="positions">
            <% @positions.each do |pos| %>
              <option value="<%= pos %>">
            <% end %>
          </datalist>
        </div>

        <div class="form-control">
          <%= f.label :hire_date, "到職日期", class: "label" %>
          <%= f.date_field :hire_date,
                          class: "input input-bordered #{'input-error' if @employee.errors[:hire_date].any?}" %>
        </div>

        <div class="form-control">
          <%= f.label :resign_date, "離職日期", class: "label" %>
          <%= f.date_field :resign_date,
                          class: "input input-bordered #{'input-error' if @employee.errors[:resign_date].any?}" %>
        </div>
      </div>
    </div>
  </div>

  <!-- 薪資結構 -->
  <div class="card bg-base-100 shadow-sm">
    <div class="card-body">
      <h2 class="card-title mb-4">薪資結構</h2>

      <div class="form-control mb-4">
        <%= f.label :base_salary, "底薪", class: "label" %>
        <%= f.number_field :base_salary,
                          step: 1,
                          class: "input input-bordered #{'input-error' if @employee.errors[:base_salary].any?}" %>
      </div>

      <!-- 津貼設定 -->
      <div class="mb-6">
        <h3 class="text-lg font-semibold mb-3">津貼項目</h3>
        <div id="allowances-container">
          <% (@employee.allowances || {}).each_with_index do |(key, value), index| %>
            <div class="flex gap-2 mb-2 allowance-item">
              <input type="text" name="employee[allowances][<%= key %>]"
                     value="<%= key %>"
                     placeholder="津貼項目"
                     class="input input-bordered flex-1">
              <input type="number" name="employee[allowances][<%= key %>]"
                     value="<%= value %>"
                     placeholder="金額"
                     class="input input-bordered w-32">
              <button type="button" class="btn btn-error btn-sm remove-allowance">移除</button>
            </div>
          <% end %>
        </div>
        <button type="button" id="add-allowance" class="btn btn-secondary btn-sm">
          新增津貼項目
        </button>
      </div>

      <!-- 扣款設定 -->
      <div>
        <h3 class="text-lg font-semibold mb-3">扣款項目</h3>
        <div id="deductions-container">
          <% (@employee.deductions || {}).each_with_index do |(key, value), index| %>
            <div class="flex gap-2 mb-2 deduction-item">
              <input type="text" name="employee[deductions][<%= key %>]"
                     value="<%= key %>"
                     placeholder="扣款項目"
                     class="input input-bordered flex-1">
              <input type="number" name="employee[deductions][<%= key %>]"
                     value="<%= value %>"
                     placeholder="金額"
                     class="input input-bordered w-32">
              <button type="button" class="btn btn-error btn-sm remove-deduction">移除</button>
            </div>
          <% end %>
        </div>
        <button type="button" id="add-deduction" class="btn btn-secondary btn-sm">
          新增扣款項目
        </button>
      </div>
    </div>
  </div>

  <!-- 操作按鈕 -->
  <div class="flex justify-end gap-3">
    <%= link_to "取消", company_employees_path(@current_company),
                class: "btn btn-outline" %>
    <%= f.submit @employee.persisted? ? "更新員工" : "建立員工",
                class: "btn btn-primary" %>
  </div>
<% end %>

<script>
// 動態新增/移除津貼扣款項目的 JavaScript
document.addEventListener('DOMContentLoaded', function() {
  // 新增津貼項目
  document.getElementById('add-allowance').addEventListener('click', function() {
    const container = document.getElementById('allowances-container');
    const div = document.createElement('div');
    div.className = 'flex gap-2 mb-2 allowance-item';
    div.innerHTML = `
      <input type="text" name="allowance_keys[]" placeholder="津貼項目" class="input input-bordered flex-1">
      <input type="number" name="allowance_values[]" placeholder="金額" class="input input-bordered w-32">
      <button type="button" class="btn btn-error btn-sm remove-allowance">移除</button>
    `;
    container.appendChild(div);
  });

  // 新增扣款項目
  document.getElementById('add-deduction').addEventListener('click', function() {
    const container = document.getElementById('deductions-container');
    const div = document.createElement('div');
    div.className = 'flex gap-2 mb-2 deduction-item';
    div.innerHTML = `
      <input type="text" name="deduction_keys[]" placeholder="扣款項目" class="input input-bordered flex-1">
      <input type="number" name="deduction_values[]" placeholder="金額" class="input input-bordered w-32">
      <button type="button" class="btn btn-error btn-sm remove-deduction">移除</button>
    `;
    container.appendChild(div);
  });

  // 移除項目
  document.addEventListener('click', function(e) {
    if (e.target.classList.contains('remove-allowance') || e.target.classList.contains('remove-deduction')) {
      e.target.parentElement.remove();
    }
  });
});
</script>
```

## 路由設定

```ruby
# config/routes.rb
Rails.application.routes.draw do
  resources :companies, only: [:index, :show] do
    member do
      patch :switch
    end

    resources :employees do
      member do
        patch :activate
      end

      collection do
        get :download_template
        get :bulk_import
        post :bulk_import
      end
    end
  end
end
```

## 測試計劃

### Model 測試擴充

```ruby
# spec/models/employee_spec.rb
RSpec.describe Employee, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:employee_id) }
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:employee_id).scoped_to(:company_id) }
  end

  describe 'scopes' do
    it 'returns only active employees' do
      # 測試 active scope
    end
  end

  describe 'salary calculations' do
    it 'calculates gross salary correctly' do
      # 測試薪資計算
    end
  end
end
```

### Service 測試

```ruby
# spec/services/employee_import_service_spec.rb
RSpec.describe EmployeeImportService do
  describe '#call' do
    it 'imports valid CSV data' do
      # 測試 CSV 匯入
    end

    it 'handles invalid data gracefully' do
      # 測試錯誤處理
    end
  end
end
```

### Controller 測試

```ruby
# spec/controllers/employees_controller_spec.rb
RSpec.describe EmployeesController, type: :controller do
  describe 'GET #index' do
    it 'returns paginated employees' do
      # 測試列表頁面
    end

    it 'filters employees by search term' do
      # 測試搜尋功能
    end
  end

  describe 'POST #create' do
    it 'creates employee with valid data' do
      # 測試建立員工
    end
  end
end
```

## 完成標準

- [ ] 員工 CRUD 功能完整實作
- [ ] 批量匯入/匯出功能正常運作
- [ ] 搜尋和篩選功能有效
- [ ] 薪資結構設定介面友善
- [ ] 表單驗證完整
- [ ] 所有測試通過
- [ ] 響應式設計適配

## 下一階段準備

完成員工管理功能後，階段三將實作薪資計算核心引擎。