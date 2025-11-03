# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SportsWaterPoloV1::Strategies::Timeout do
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
          'team' => 'us',
          'duration' => 60,
          'time' => 240000,
          'period' => 2
        }
      end

      it 'returns true' do
        expect(described_class.validate!(payload)).to be true
      end
    end

    context 'with minimal payload' do
      let(:payload) { {} }

      it 'returns true' do
        expect(described_class.validate!(payload)).to be true
      end
    end
  end

  describe '.apply!' do
    let(:payload) do
      {
        'team' => 'us',
        'duration' => 60,
        'time' => 240000,
        'period' => 2
      }
    end

    context 'with empty accumulator' do
      let(:acc) { {} }

      it 'initializes timeouts hash' do
        result = described_class.apply!(acc, event)
        expect(result['timeouts']).to be_a(Hash)
        expect(result['timeouts']['us']).to be_an(Array)
      end

      it 'records timeout details' do
        result = described_class.apply!(acc, event)
        timeout = result['timeouts']['us'].first

        expect(timeout[:id]).to eq(1)
        expect(timeout[:time]).to eq(240000)
        expect(timeout[:period]).to eq(2)
        expect(timeout[:duration]).to eq(60)
        expect(timeout[:seq]).to eq(1)
      end
    end

    context 'with existing accumulator' do
      let(:acc) do
        {
          'timeouts' => {
            'us' => [{ id: 0, time: 180000, period: 1, seq: 0 }],
            'them' => []
          }
        }
      end

      it 'appends to timeouts array for correct team' do
        result = described_class.apply!(acc, event)
        expect(result['timeouts']['us'].size).to eq(2)
        expect(result['timeouts']['them'].size).to eq(0)
      end
    end
  end

  describe '.timeline' do
    let(:payload) do
      {
        'team' => 'us',
        'time' => 240000,
        'period' => 2
      }
    end

    it 'returns timeline hash' do
      result = described_class.timeline(event)
      expect(result).to be_a(Hash)
      expect(result).to include(:text, :icon, :color, :timestamp)
    end

    it 'includes team in text' do
      result = described_class.timeline(event)
      expect(result[:text]).to include('Us')
      expect(result[:text]).to include('timeout')
    end

    it 'uses stopwatch icon' do
      result = described_class.timeline(event)
      expect(result[:icon]).to eq('⏱️')
    end

    it 'uses blue color' do
      result = described_class.timeline(event)
      expect(result[:color]).to eq('blue')
    end
  end
end
