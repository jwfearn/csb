require 'spec_helper'
require_relative '../convoy_bundler'

RSpec.describe ConvoyBundler do
  let(:b) { described_class.new }
  let(:bad_count) { '1 A B M x' }
  let(:bad_day) { '1 A B x' }
  let(:mwf) {
    <<~HERE
      1 A B M
      2 B C W
      3 C D F
    HERE
  }

  describe '#ingest' do
    it 'rejects input with wrong number of fields' do
      expect { b.ingest_str(bad_count).inspect }.to raise_error(StandardError)
    end

    it 'rejects input with wrong invalid day of week' do
      expect { b.ingest_str(bad_day).inspect }.to raise_error(StandardError)
    end

    it 'accepts good input' do
      expect(b.ingest_str(mwf).inspect).not_to be_empty
    end
  end
end
