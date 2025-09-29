class CreateInsurances < ActiveRecord::Migration[8.0]
  def change
    create_table :insurances do |t|
      t.string :insurance_type, null: false # 'labor', 'health', 'labor_pension', 'occupational_injury'
      t.integer :grade_level, null: false # 級距等級 (1, 2, 3...)
      t.decimal :salary_min, precision: 10, scale: 2, null: false # 薪資下限
      t.decimal :salary_max, precision: 10, scale: 2 # 薪資上限 (最高級距可為null)
      t.decimal :premium_base, precision: 10, scale: 2, null: false # 投保金額
      t.decimal :rate, precision: 5, scale: 4, null: false # 保險費率 (如0.115代表11.5%)
      t.decimal :employee_ratio, precision: 4, scale: 3, null: false # 勞工負擔比例 (如0.2代表20%)
      t.decimal :employer_ratio, precision: 4, scale: 3, null: false # 雇主負擔比例 (如0.7代表70%)
      t.decimal :government_ratio, precision: 4, scale: 3, default: 0 # 政府負擔比例 (如0.1代表10%)
      t.date :effective_date, null: false # 生效日期
      t.date :expiry_date # 失效日期 (可為null，表示目前有效)

      t.timestamps
    end

    add_index :insurances, [ :insurance_type, :effective_date, :expiry_date ], name: 'index_insurances_on_type_and_dates'
    add_index :insurances, [ :salary_min, :salary_max ], name: 'index_insurances_on_salary_range'
    add_index :insurances, :insurance_type
    add_index :insurances, :grade_level
  end
end
