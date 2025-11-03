# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SportsWaterPoloV1::Strategies::PeriodStart do
  let(:event) do
    double('Event',
      id: 1,
      side: 'us',
      payload: payload,
      seq: 1)
  end

  describe '.validate!' do
    context 'with valid payload' do
      let(:payload) do
        {
          'period' => 1,
          'time' => 480000
        }
      end

      it 'returns true' do
        expect(described_class.validate!(payload)).to be true
      end
    end

    context 'with missing period' do
      let(:payload) do
        {
          'time' => 480000
        }
      end

      it 'raises ValidationError' do
        expect {
          described_class.validate!(payload)
        }.to raise_error(SportsWaterPoloV1::Strategies::ValidationError, /period is required/)
      end
    end
  end

  describe '.apply!' do
    let(:payload) do
      {
        'period' => 2,
        'time' => 480000
      }
    end

    context 'with empty accumulator' do
      let(:acc) { {} }

      it 'initializes period_starts array' do
        result = described_class.apply!(acc, event)
        expect(result['period_starts']).to be_an(Array)
        expect(result['period_starts'].size).to eq(1)
      end

      it 'sets current_period' do
        result = described_class.apply!(acc, event)
        expect(result['current_period']).to eq(2)
      end

      it 'records period start details' do
        result = described_class.apply!(acc, event)
        period_start = result['period_starts'].first

        expect(period_start[:id]).to eq(1)
        expect(period_start[:period]).to eq(2)
        expect(period_start[:time]).to eq(480000)
        expect(period_start[:seq]).to eq(1)
      end
    end
  end

  describe '.timeline' do
    let(:payload) do
      {
        'period' => 2,
        'time' => 480000
      }
    end

    it 'returns timeline hash' do
      result = described_class.timeline(event)
      expect(result).to be_a(Hash)
      expect(result).to include(:text, :icon, :color, :timestamp)
    end

    it 'includes period number in text' do
      result = described_class.timeline(event)
      expect(result[:text]).to include('Period 2')
    end

    it 'uses bell icon' do
      result = described_class.timeline(event)
      expect(result[:icon]).to eq('🔔')
    end

    it 'uses gray color' do
      result = described_class.timeline(event)
      expect(result[:color]).to eq('gray')
    end
  end
end
