# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SportsWaterPoloV1::Strategies::FiveMeter do
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

      it 'initializes five_meter_penalties hash' do
        result = described_class.apply!(acc, event)
        expect(result['five_meter_penalties']).to be_a(Hash)
        expect(result['five_meter_penalties']['them']).to eq(1)
        expect(result['five_meter_penalties']['us']).to eq(0)
      end

      it 'initializes five_meter_events array' do
        result = described_class.apply!(acc, event)
        expect(result['five_meter_events']).to be_an(Array)
        expect(result['five_meter_events'].size).to eq(1)
      end

      it 'records five meter penalty details' do
        result = described_class.apply!(acc, event)
        penalty = result['five_meter_events'].first

        expect(penalty[:id]).to eq(1)
        expect(penalty[:side]).to eq('them')
        expect(penalty[:fouler_id]).to eq('123')
        expect(penalty[:drew_penalty_id]).to eq('456')
        expect(penalty[:time]).to eq(90000)
        expect(penalty[:period]).to eq(2)
        expect(penalty[:seq]).to eq(1)
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

    it 'includes fouler in text' do
      result = described_class.timeline(event)
      expect(result[:text]).to include('123')
    end

    it 'uses flag icon' do
      result = described_class.timeline(event)
      expect(result[:icon]).to eq('🚩')
    end

    it 'uses orange color' do
      result = described_class.timeline(event)
      expect(result[:color]).to eq('orange')
    end
  end
end
