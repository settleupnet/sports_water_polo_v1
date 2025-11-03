# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SportsWaterPoloV1::Strategies::PeriodEnd do
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
          'time' => 0
        }
      end

      it 'returns true' do
        expect(described_class.validate!(payload)).to be true
      end
    end

    context 'with missing period' do
      let(:payload) do
        {
          'time' => 0
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
        'period' => 1
      }
    end

    context 'with empty accumulator' do
      let(:acc) { {} }

      it 'initializes periods_completed array' do
        result = described_class.apply!(acc, event)
        expect(result['periods_completed']).to be_an(Array)
        expect(result['periods_completed']).to include(1)
      end
    end

    context 'with existing periods_completed' do
      let(:acc) { { 'periods_completed' => [1, 2] } }
      let(:payload) { { 'period' => 3 } }

      it 'appends new period' do
        result = described_class.apply!(acc, event)
        expect(result['periods_completed']).to eq([1, 2, 3])
      end

      it 'does not duplicate existing periods' do
        payload = { 'period' => 2 }
        event = double('Event', id: 2, side: 'us', payload: payload, seq: 2)
        result = described_class.apply!(acc, event)
        expect(result['periods_completed']).to eq([1, 2])
      end
    end
  end

  describe '.timeline' do
    let(:payload) do
      {
        'period' => 1
      }
    end

    it 'returns timeline hash' do
      result = described_class.timeline(event)
      expect(result).to be_a(Hash)
      expect(result).to include(:text, :icon, :color, :timestamp)
    end

    it 'includes period number in text' do
      result = described_class.timeline(event)
      expect(result[:text]).to include('Period 1')
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
