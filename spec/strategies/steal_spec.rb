# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SportsWaterPoloV1::Strategies::Steal do
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

    context 'with minimal valid payload' do
      let(:payload) do
        {
          'primary_player_id' => '123'
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

    context 'with invalid time format' do
      let(:payload) do
        {
          'primary_player_id' => '123',
          'time' => 'invalid'
        }
      end

      it 'raises ValidationError' do
        expect {
          described_class.validate!(payload)
        }.to raise_error(SportsWaterPoloV1::Strategies::ValidationError, /time must be an integer/)
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

      it 'initializes steals hash' do
        result = described_class.apply!(acc, event)
        expect(result['steals']).to be_a(Hash)
        expect(result['steals']['us']).to eq(1)
        expect(result['steals']['them']).to eq(0)
      end

      it 'initializes steal_events array' do
        result = described_class.apply!(acc, event)
        expect(result['steal_events']).to be_an(Array)
        expect(result['steal_events'].size).to eq(1)
      end

      it 'records steal details' do
        result = described_class.apply!(acc, event)
        steal = result['steal_events'].first

        expect(steal[:id]).to eq(1)
        expect(steal[:side]).to eq('us')
        expect(steal[:stealer_id]).to eq('123')
        expect(steal[:stolen_from_id]).to eq('456')
        expect(steal[:time]).to eq(90000)
        expect(steal[:period]).to eq(2)
        expect(steal[:seq]).to eq(1)
      end
    end

    context 'with existing accumulator' do
      let(:acc) do
        {
          'steal_events' => [
            { id: 0, side: 'them', stealer_id: '789', time: 60000, seq: 0 }
          ],
          'steals' => { 'us' => 0, 'them' => 1 }
        }
      end

      it 'appends to steal_events array' do
        result = described_class.apply!(acc, event)
        expect(result['steal_events'].size).to eq(2)
      end

      it 'increments correct side steals' do
        result = described_class.apply!(acc, event)
        expect(result['steals']['us']).to eq(1)
        expect(result['steals']['them']).to eq(1)
      end
    end

    context 'for them side' do
      let(:event) do
        double('Event',
          id: 2,
          side: 'them',
          payload: payload,
          seq: 2)
      end
      let(:acc) { { 'steals' => { 'us' => 1, 'them' => 0 } } }

      it 'increments them steals' do
        result = described_class.apply!(acc, event)
        expect(result['steals']['them']).to eq(1)
        expect(result['steals']['us']).to eq(1)
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

    it 'includes stealer in text' do
      result = described_class.timeline(event)
      expect(result[:text]).to include('123')
    end

    it 'includes stolen_from in text when present' do
      result = described_class.timeline(event)
      expect(result[:text]).to include('456')
    end

    it 'includes time and period' do
      result = described_class.timeline(event)
      expect(result[:text]).to include('1:30')
      expect(result[:text]).to include('Q2')
    end

    it 'uses steal icon' do
      result = described_class.timeline(event)
      expect(result[:icon]).to eq('🤺')
    end

    it 'uses blue color' do
      result = described_class.timeline(event)
      expect(result[:color]).to eq('blue')
    end
  end
end
