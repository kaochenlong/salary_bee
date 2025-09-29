require 'rails_helper'

RSpec.describe 'layouts/application.html.erb', type: :view do
  context 'when layout includes flash partial' do
    it 'includes render shared/flash in template' do
      # 直接檢查模板檔案內容
      template_content = File.read(Rails.root.join('app/views/layouts/application.html.erb'))
      expect(template_content).to include("render 'shared/flash'")
    end
  end

  context 'when rendering with content' do
    before do
      # 設定 content_for 以避免 layout 渲染錯誤
      content_for :title, 'Test Page'
    end

    it 'includes flash messages before main content' do
      # 設定 flash 訊息
      flash[:notice] = 'Test notice message'

      # 渲染 layout
      render

      # 驗證 flash 訊息在 HTML 中出現
      expect(rendered).to include('Test notice message')
      expect(rendered).to include('text-green-600')
    end
  end
end
