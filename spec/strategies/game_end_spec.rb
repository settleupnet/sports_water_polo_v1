# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SportsWaterPoloV1::Strategies::GameEnd do
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
          'note' => 'Great game!'
        }
      end

      it 'returns true' do
        expect(described_class.validate!(payload)).to be true
      end
    end

    context 'with empty payload' do
      let(:payload) { {} }

      it 'returns true' do
        expect(described_class.validate!(payload)).to be true
      end
    end
  end

  describe '.apply!' do
    let(:payload) do
      {
        'note' => 'Great game!'
      }
    end

    context 'with empty accumulator' do
      let(:acc) { {} }

      it 'sets game_status to completed' do
        result = described_class.apply!(acc, event)
        expect(result['game_status']).to eq('completed')
      end

      it 'sets game_end_note when present' do
        result = described_class.apply!(acc, event)
        expect(result['game_end_note']).to eq('Great game!')
      end

      it 'handles missing note' do
        event_no_note = double('Event', id: 2, side: 'us', payload: {}, seq: 2)
        result = described_class.apply!(acc, event_no_note)
        expect(result['game_end_note']).to be_nil
      end
    end

    context 'with period in payload' do
      let(:payload) { { 'period' => 4, 'note' => 'Regulation win' } }

      it 'records final_period' do
        acc = {}
        result = described_class.apply!(acc, event)
        expect(result['final_period']).to eq(4)
      end
    end
  end

  describe '.timeline' do
    context 'without note' do
      let(:payload) { {} }

      it 'returns timeline hash' do
        result = described_class.timeline(event)
        expect(result).to be_a(Hash)
        expect(result).to include(:text, :icon, :color, :timestamp)
      end

      it 'shows Game Over text' do
        result = described_class.timeline(event)
        expect(result[:text]).to eq('Game Over')
      end

      it 'has no timestamp' do
        result = described_class.timeline(event)
        expect(result[:timestamp]).to be_nil
      end
    end

    context 'with note' do
      let(:payload) do
        {
          'note' => 'Great game!'
        }
      end

      it 'includes note in text' do
        result = described_class.timeline(event)
        expect(result[:text]).to eq('Game Over - Great game!')
      end
    end

    it 'uses checkered flag icon' do
      payload = {}
      event = double('Event', id: 1, side: 'us', payload: payload, seq: 1)
      result = described_class.timeline(event)
      expect(result[:icon]).to eq('🏁')
    end

    it 'uses black color' do
      payload = {}
      event = double('Event', id: 1, side: 'us', payload: payload, seq: 1)
      result = described_class.timeline(event)
      expect(result[:color]).to eq('black')
    end
  end
end
