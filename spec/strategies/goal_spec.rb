# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SportsWaterPoloV1::Strategies::Goal do
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
          'period' => 2,
          'method' => 'regular'
        }
      end

      it 'returns true' do
        expect(described_class.validate!(payload)).to be true
      end
    end

    context 'with minimal valid payload' do
      let(:payload) do
        {
          'primary_player_id' => '123',
          'time' => 45000
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
          'time' => '90 seconds'
        }
      end

      it 'raises ValidationError' do
        expect {
          described_class.validate!(payload)
        }.to raise_error(SportsWaterPoloV1::Strategies::ValidationError, /time must be an integer/)
      end
    end

    context 'with valid time formats' do
      it 'accepts milliseconds time' do
        payload = { 'primary_player_id' => '123', 'time' => 30000 }
        expect(described_class.validate!(payload)).to be true
      end

      it 'accepts large milliseconds values' do
        payload = { 'primary_player_id' => '123', 'time' => 765000 }
        expect(described_class.validate!(payload)).to be true
      end

      it 'accepts zero time' do
        payload = { 'primary_player_id' => '123', 'time' => 0 }
        expect(described_class.validate!(payload)).to be true
      end
    end
  end

  describe '.apply!' do
    let(:payload) do
      {
        'primary_player_id' => '123',
        'secondary_player_id' => '456',
        'time' => 90000,
        'period' => 2,
        'method' => 'regular'
      }
    end

    context 'with empty accumulator' do
      let(:acc) { {} }

      it 'initializes goals array' do
        result = described_class.apply!(acc, event)
        expect(result['goals']).to be_an(Array)
        expect(result['goals'].size).to eq(1)
      end

      it 'initializes score hash' do
        result = described_class.apply!(acc, event)
        expect(result['score']).to be_a(Hash)
        expect(result['score']['us']).to eq(1)
        expect(result['score']['them']).to eq(0)
      end

      it 'records goal details' do
        result = described_class.apply!(acc, event)
        goal = result['goals'].first

        expect(goal[:id]).to eq(1)
        expect(goal[:side]).to eq('us')
        expect(goal[:scorer_id]).to eq('123')
        expect(goal[:assist_id]).to eq('456')
        expect(goal[:time]).to eq(90000)
        expect(goal[:period]).to eq(2)
        expect(goal[:method]).to eq('regular')
        expect(goal[:seq]).to eq(1)
      end
    end

    context 'with existing accumulator' do
      let(:acc) do
        {
          'goals' => [
            { id: 0, side: 'them', scorer_id: '789', time: 60000, seq: 0 }
          ],
          'score' => { 'us' => 0, 'them' => 1 }
        }
      end

      it 'appends to goals array' do
        result = described_class.apply!(acc, event)
        expect(result['goals'].size).to eq(2)
      end

      it 'increments correct side score' do
        result = described_class.apply!(acc, event)
        expect(result['score']['us']).to eq(1)
        expect(result['score']['them']).to eq(1)
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
      let(:acc) { { 'score' => { 'us' => 1, 'them' => 0 } } }

      it 'increments them score' do
        result = described_class.apply!(acc, event)
        expect(result['score']['them']).to eq(1)
        expect(result['score']['us']).to eq(1)
      end
    end

    context 'for neutral side' do
      let(:event) do
        double('Event',
          id: 3,
          side: 'neutral',
          payload: payload,
          seq: 3)
      end
      let(:acc) { { 'score' => { 'us' => 1, 'them' => 1 } } }

      it 'does not increment any score' do
        result = described_class.apply!(acc, event)
        expect(result['score']['us']).to eq(1)
        expect(result['score']['them']).to eq(1)
      end

      it 'still records the goal' do
        result = described_class.apply!(acc, event)
        expect(result['goals'].size).to eq(1)
      end
    end
  end

  describe '.timeline' do
    let(:payload) do
      {
        'primary_player_id' => '123',
        'time' => 90000,
        'period' => 2,
        'method' => 'regular'
      }
    end

    it 'returns timeline hash' do
      result = described_class.timeline(event)
      expect(result).to be_a(Hash)
      expect(result).to include(:text, :icon, :color, :timestamp)
    end

    it 'includes scorer in text' do
      result = described_class.timeline(event)
      expect(result[:text]).to include('123')
    end

    it 'includes time and period' do
      result = described_class.timeline(event)
      expect(result[:text]).to include('1:30')
      expect(result[:text]).to include('Q2')
    end

    context 'with penalty method' do
      let(:payload) do
        {
          'primary_player_id' => '123',
          'time' => 90000,
          'period' => 2,
          'method' => 'penalty'
        }
      end

      it 'includes method in text' do
        result = described_class.timeline(event)
        expect(result[:text]).to include('Penalty')
      end
    end

    context 'with assist' do
      let(:payload) do
        {
          'primary_player_id' => '123',
          'secondary_player_id' => '456',
          'time' => 90000,
          'period' => 2
        }
      end

      it 'includes assist in text' do
        result = described_class.timeline(event)
        expect(result[:text]).to include('Assist: 456')
      end
    end

    it 'uses goal icon' do
      result = described_class.timeline(event)
      expect(result[:icon]).to eq('🥅')
    end

    it 'uses green color' do
      result = described_class.timeline(event)
      expect(result[:color]).to eq('green')
    end
  end
end
