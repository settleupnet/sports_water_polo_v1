# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SportsWaterPoloV1::Strategies::StartShootout do
  let(:event) do
    double('Event',
      id: 1,
      side: 'us',
      payload: payload,
      seq: 1)
  end

  describe '.validate!' do
    context 'with any payload' do
      let(:payload) { {} }

      it 'returns true' do
        expect(described_class.validate!(payload)).to be true
      end
    end
  end

  describe '.apply!' do
    let(:payload) { {} }

    context 'with empty accumulator' do
      let(:acc) { {} }

      it 'initializes shootout hash' do
        result = described_class.apply!(acc, event)
        expect(result['shootout']).to be_a(Hash)
        expect(result['shootout']['started']).to be true
      end

      it 'sets current_period to -1' do
        result = described_class.apply!(acc, event)
        expect(result['current_period']).to eq(-1)
      end
    end

    context 'with existing accumulator' do
      let(:acc) do
        {
          'current_period' => 4,
          'score' => { 'us' => 10, 'them' => 10 }
        }
      end

      it 'updates current_period to -1' do
        result = described_class.apply!(acc, event)
        expect(result['current_period']).to eq(-1)
      end

      it 'preserves existing accumulator data' do
        result = described_class.apply!(acc, event)
        expect(result['score']).to eq({ 'us' => 10, 'them' => 10 })
      end
    end
  end

  describe '.timeline' do
    let(:payload) { {} }

    it 'returns timeline hash' do
      result = described_class.timeline(event)
      expect(result).to be_a(Hash)
      expect(result).to include(:text, :icon, :color, :timestamp)
    end

    it 'shows Shootout begins text' do
      result = described_class.timeline(event)
      expect(result[:text]).to eq('Shootout begins')
    end

    it 'uses target icon' do
      result = described_class.timeline(event)
      expect(result[:icon]).to eq('🎯')
    end

    it 'uses yellow color' do
      result = described_class.timeline(event)
      expect(result[:color]).to eq('yellow')
    end
  end
end
