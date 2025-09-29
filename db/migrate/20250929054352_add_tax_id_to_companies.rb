class AddTaxIdToCompanies < ActiveRecord::Migration[8.0]
  def change
    # 先新增允許 NULL 的欄位
    add_column :companies, :tax_id, :string, limit: 8, null: true

    # 為現有公司設定預設統編（稍後需要手動更新為正確統編）
    reversible do |dir|
      dir.up do
        Company.reset_column_information
        Company.find_each.with_index do |company, index|
          # 為現有公司產生暫時的統編（需要後續手動更新）
          temp_tax_id = "0000000#{index % 10}"
          company.update_column(:tax_id, temp_tax_id)
        end
      end
    end

    # 設定 NOT NULL 約束和唯一索引
    change_column_null :companies, :tax_id, false
    add_index :companies, :tax_id, unique: true
  end
end
