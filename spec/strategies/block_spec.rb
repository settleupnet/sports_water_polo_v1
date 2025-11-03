# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SportsWaterPoloV1::Strategies::Block do
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
          'primary_player_id' => '123',
          'time' => 90000,
          'period' => 2
        }
      end

      it 'returns true' do
        expect(described_class.validate!(payload)).to be true
      end
    end

    context 'with missing primary_player_id' do
      let(:payload) do
        {
          'time' => 90000
        }
      end

      it 'raises ValidationError' do
        expect {
          described_class.validate!(payload)
        }.to raise_error(SportsWaterPoloV1::Strategies::ValidationError, /primary_player_id is required/)
      end
    end
  end

  describe '.apply!' do
    let(:payload) do
      {
        'primary_player_id' => '123',
        'secondary_player_id' => '456',
        'time' => 90000,
        'period' => 2
      }
    end

    context 'with empty accumulator' do
      let(:acc) { {} }

      it 'initializes blocks hash' do
        result = described_class.apply!(acc, event)
        expect(result['blocks']).to be_a(Hash)
        expect(result['blocks']['us']).to eq(1)
        expect(result['blocks']['them']).to eq(0)
      end

      it 'initializes block_events array' do
        result = described_class.apply!(acc, event)
        expect(result['block_events']).to be_an(Array)
        expect(result['block_events'].size).to eq(1)
      end

      it 'records block details' do
        result = described_class.apply!(acc, event)
        block = result['block_events'].first

        expect(block[:id]).to eq(1)
        expect(block[:side]).to eq('us')
        expect(block[:blocker_id]).to eq('123')
        expect(block[:shooter_id]).to eq('456')
        expect(block[:time]).to eq(90000)
        expect(block[:period]).to eq(2)
        expect(block[:seq]).to eq(1)
      end
    end
  end

  describe '.timeline' do
    let(:payload) do
      {
        'primary_player_id' => '123',
        'secondary_player_id' => '456',
        'time' => 90000,
        'period' => 2
      }
    end

    it 'returns timeline hash' do
      result = described_class.timeline(event)
      expect(result).to be_a(Hash)
      expect(result).to include(:text, :icon, :color, :timestamp)
    end

    it 'includes blocker in text' do
      result = described_class.timeline(event)
      expect(result[:text]).to include('123')
    end

    it 'uses shield icon' do
      result = described_class.timeline(event)
      expect(result[:icon]).to eq('🛡️')
    end

    it 'uses purple color' do
      result = described_class.timeline(event)
      expect(result[:color]).to eq('purple')
    end
  end
end
