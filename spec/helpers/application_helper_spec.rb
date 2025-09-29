require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#flash_css_class' do
    context 'when flash type is alert' do
      it 'returns alert CSS classes for symbol' do
        expect(helper.flash_css_class(:alert)).to eq('text-red-600 bg-red-50 border border-red-200 p-4 rounded')
      end

      it 'returns alert CSS classes for string' do
        expect(helper.flash_css_class('alert')).to eq('text-red-600 bg-red-50 border border-red-200 p-4 rounded')
      end
    end

    context 'when flash type is notice' do
      it 'returns notice CSS classes for symbol' do
        expect(helper.flash_css_class(:notice)).to eq('text-green-600 bg-green-50 border border-green-200 p-4 rounded')
      end

      it 'returns notice CSS classes for string' do
        expect(helper.flash_css_class('notice')).to eq('text-green-600 bg-green-50 border border-green-200 p-4 rounded')
      end
    end

    context 'when flash type is unknown' do
      it 'returns default CSS classes for unknown symbol' do
        expect(helper.flash_css_class(:unknown)).to eq('text-gray-600 bg-gray-50 border border-gray-200 p-4 rounded')
      end

      it 'returns default CSS classes for unknown string' do
        expect(helper.flash_css_class('unknown')).to eq('text-gray-600 bg-gray-50 border border-gray-200 p-4 rounded')
      end

      it 'returns default CSS classes for nil' do
        expect(helper.flash_css_class(nil)).to eq('text-gray-600 bg-gray-50 border border-gray-200 p-4 rounded')
      end
    end
  end
end
