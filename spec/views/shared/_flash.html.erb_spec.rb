require 'rails_helper'

RSpec.describe 'shared/_flash.html.erb', type: :view do
  before do
    # 確保 helper method 可用
    allow(view).to receive(:flash_css_class) do |type|
      case type.to_s
      when 'alert'
        'text-red-600 bg-red-50 border border-red-200 p-4 rounded'
      when 'notice'
        'text-green-600 bg-green-50 border border-green-200 p-4 rounded'
      else
        'text-gray-600 bg-gray-50 border border-gray-200 p-4 rounded'
      end
    end
  end

  context 'when there is a single alert message' do
    it 'displays the alert message with correct CSS classes' do
      allow(view).to receive(:flash).and_return({ alert: 'Error message' })

      render

      expect(rendered).to include('Error message')
      expect(rendered).to include('text-red-600 bg-red-50 border border-red-200 p-4 rounded')
    end
  end

  context 'when there is a single notice message' do
    it 'displays the notice message with correct CSS classes' do
      allow(view).to receive(:flash).and_return({ notice: 'Success message' })

      render

      expect(rendered).to include('Success message')
      expect(rendered).to include('text-green-600 bg-green-50 border border-green-200 p-4 rounded')
    end
  end

  context 'when there are multiple flash messages' do
    it 'displays both alert and notice messages with their respective CSS classes' do
      allow(view).to receive(:flash).and_return({
        alert: 'Error message',
        notice: 'Success message'
      })

      render

      expect(rendered).to include('Error message')
      expect(rendered).to include('Success message')
      expect(rendered).to include('text-red-600 bg-red-50 border border-red-200 p-4 rounded')
      expect(rendered).to include('text-green-600 bg-green-50 border border-green-200 p-4 rounded')
    end
  end

  context 'when flash is empty' do
    it 'does not render any content' do
      allow(view).to receive(:flash).and_return({})

      render

      expect(rendered.strip).to be_empty
    end
  end

  context 'when flash contains nil or empty messages' do
    it 'does not render content for nil messages' do
      allow(view).to receive(:flash).and_return({ alert: nil, notice: '' })

      render

      expect(rendered.strip).to be_empty
    end
  end

  context 'when flash contains HTML content' do
    it 'properly escapes HTML content' do
      allow(view).to receive(:flash).and_return({
        alert: '<script>alert("xss")</script>'
      })

      render

      expect(rendered).to include('&lt;script&gt;')
      expect(rendered).to include('&lt;/script&gt;')
      expect(rendered).not_to include('<script>')
    end
  end

  context 'when flash contains long messages' do
    it 'handles long messages properly' do
      long_message = 'This is a very long message that should be handled properly by the flash partial without breaking the layout or causing any display issues.'
      allow(view).to receive(:flash).and_return({ notice: long_message })

      render

      expect(rendered).to include(long_message)
      expect(rendered).to include('text-green-600 bg-green-50 border border-green-200 p-4 rounded')
    end
  end
end
