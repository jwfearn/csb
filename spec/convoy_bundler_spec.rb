require 'spec_helper'
require_relative '../convoy_bundler'

RSpec.describe ConvoyBundler do
  let(:bad_count) { described_class.new('1 A B M x') }
  let(:bad_day) { described_class.new('1 A B x') }
  let(:empty) { described_class.new('') }
  let(:hundred) { described_class.new(test_filepath('hundred_shipments')) }
  let(:mwf) { described_class.new(test_filepath('mwf')) }
  let(:one) { described_class.new(test_filepath('one_bundle')) }
  let(:simple) { described_class.new(test_filepath('simple')) }
  let(:thousand) { described_class.new(test_filepath('thousand_shipments')) }

  describe '.new' do
    it 'rejects input with wrong number of fields' do
      expect { bad_count.inspect }.to raise_error(StandardError)
    end

    it 'rejects input with wrong invalid day of week' do
      expect { bad_day.inspect }.to raise_error(StandardError)
    end

    it 'accepts good input' do
      expect(mwf.inspect).not_to be_empty
    end
  end

  describe '#count' do
    it 'one' do
      expect(one.count).to eq(1)
    end

    it 'simple' do
      expect(simple.count).to eq(2)
    end

    it 'mwf' do
      expect(mwf.count).to eq(3)
    end

    it 'hundred_shipments' do
      expect(hundred.count).to eq(57)
    end

    it 'thousand_shipments' do
      expect(thousand.count).to satisfy { |n| n > 0 && n < 1_000 } # 319
    end
  end

  describe '#bundles' do
    it 'empty' do
      expect(empty.bundles).to be_empty
    end

    it 'one' do
      expect(one.bundles).to contain_exactly('69 34 98 62 78')
    end

    it 'mwf' do
      expect(mwf.bundles).to match_array %w[1 2 3]
    end

    it 'simple' do
      expect(simple.bundles).to contain_exactly('3 44 22 99', '1 2')
    end
  end

  def test_filepath(basename)
    File.join(File.dirname(__FILE__), "../tests/#{basename}")
  end
end
