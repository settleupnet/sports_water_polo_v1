# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SportsWaterPoloV1::Strategies::Misconduct do
  let(:event) do
    double('Event',
      id: 1,
      side: 'them',
      payload: payload,
      seq: 1)
  end

  describe '.validate!' do
    context 'with valid payload' do
      let(:payload) do
        {
          'card_type' => 'yellow',
          'time' => 90000,
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
        'primary_player_id' => '123',
        'card_type' => 'yellow',
        'reason' => 'unsportsmanlike_conduct',
        'time' => 90000,
        'period' => 2
      }
    end

    context 'with empty accumulator' do
      let(:acc) { {} }

      it 'initializes misconducts hash' do
        result = described_class.apply!(acc, event)
        expect(result['misconducts']).to be_a(Hash)
        expect(result['misconducts']['them']['yellow']).to eq(1)
        expect(result['misconducts']['them']['red']).to eq(0)
      end

      it 'initializes misconduct_events array' do
        result = described_class.apply!(acc, event)
        expect(result['misconduct_events']).to be_an(Array)
        expect(result['misconduct_events'].size).to eq(1)
      end

      it 'records misconduct details' do
        result = described_class.apply!(acc, event)
        misconduct = result['misconduct_events'].first

        expect(misconduct[:id]).to eq(1)
        expect(misconduct[:side]).to eq('them')
        expect(misconduct[:recipient_id]).to eq('123')
        expect(misconduct[:card_type]).to eq('yellow')
        expect(misconduct[:reason]).to eq('unsportsmanlike_conduct')
        expect(misconduct[:time]).to eq(90000)
        expect(misconduct[:period]).to eq(2)
        expect(misconduct[:seq]).to eq(1)
      end
    end

    context 'with red card' do
      let(:payload) do
        {
          'primary_player_id' => '456',
          'card_type' => 'red',
          'reason' => 'brutality',
          'is_brutality' => true,
          'time' => 60000,
          'period' => 3
        }
      end

      it 'increments red card count' do
        acc = { 'misconducts' => { 'them' => { 'yellow' => 0, 'red' => 0 } } }
        result = described_class.apply!(acc, event)
        expect(result['misconducts']['them']['red']).to eq(1)
      end
    end
  end

  describe '.timeline' do
    let(:payload) do
      {
        'primary_player_id' => '123',
        'card_type' => 'yellow',
        'reason' => 'unsportsmanlike_conduct',
        'time' => 90000,
        'period' => 2
      }
    end

    it 'returns timeline hash' do
      result = described_class.timeline(event)
      expect(result).to be_a(Hash)
      expect(result).to include(:text, :icon, :color, :timestamp)
    end

    it 'includes card type and recipient in text' do
      result = described_class.timeline(event)
      expect(result[:text]).to include('Yellow')
      expect(result[:text]).to include('123')
    end

    it 'uses red square icon' do
      result = described_class.timeline(event)
      expect(result[:icon]).to eq('🟥')
    end

    it 'uses red color' do
      result = described_class.timeline(event)
      expect(result[:color]).to eq('red')
    end
  end
end
