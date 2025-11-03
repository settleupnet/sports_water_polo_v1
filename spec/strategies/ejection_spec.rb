# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SportsWaterPoloV1::Strategies::Ejection do
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
          'duration' => 20,
          'reason' => 'ordinary_foul',
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
          'primary_player_id' => '123',
          'time' => 90000
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
        'duration' => 20,
        'reason' => 'ordinary_foul',
        'time' => 90000,
        'period' => 2
      }
    end

    context 'with empty accumulator' do
      let(:acc) { {} }

      it 'initializes exclusions array' do
        result = described_class.apply!(acc, event)
        expect(result['exclusions']).to be_an(Array)
        expect(result['exclusions'].size).to eq(1)
      end

      it 'initializes player_status hash' do
        result = described_class.apply!(acc, event)
        expect(result['player_status']).to be_a(Hash)
        expect(result['player_status']['123']).to be_present
      end

      it 'records exclusion details' do
        result = described_class.apply!(acc, event)
        exclusion = result['exclusions'].first

        expect(exclusion[:id]).to eq(1)
        expect(exclusion[:side]).to eq('them')
        expect(exclusion[:player_id]).to eq('123')
        expect(exclusion[:duration]).to eq(20)
        expect(exclusion[:reason]).to eq('ordinary_foul')
        expect(exclusion[:time]).to eq(90000)
        expect(exclusion[:period]).to eq(2)
        expect(exclusion[:seq]).to eq(1)
      end

      it 'sets player status to excluded' do
        result = described_class.apply!(acc, event)
        player_status = result['player_status']['123']

        expect(player_status[:status]).to eq('excluded')
        expect(player_status[:duration]).to eq(20)
        expect(player_status[:until_time]).to be_present
      end
    end

    context 'with existing accumulator' do
      let(:acc) do
        {
          'exclusions' => [
            { id: 0, player_id: '456', time: 60000, seq: 0 }
          ],
          'player_status' => {
            '456' => { status: 'excluded', until_time: 40000, duration: 20 }
          }
        }
      end

      it 'appends to exclusions array' do
        result = described_class.apply!(acc, event)
        expect(result['exclusions'].size).to eq(2)
      end

      it 'updates player_status for new player' do
        result = described_class.apply!(acc, event)
        expect(result['player_status']['123']).to be_present
        expect(result['player_status']['456']).to be_present
      end
    end

    describe 'return time calculation' do
      let(:acc) { {} }

      it 'calculates correct return time for 20 second exclusion' do
        payload['time'] = 120000  # 2:00
        payload['duration'] = 20

        result = described_class.apply!(acc, event)
        player_status = result['player_status']['123']

        expect(player_status[:until_time]).to eq(100000)  # 1:40
      end

      it 'handles zero return time' do
        payload['time'] = 10000  # 0:10
        payload['duration'] = 20

        result = described_class.apply!(acc, event)
        player_status = result['player_status']['123']

        expect(player_status[:until_time]).to eq(0)  # 0:00
      end

      it 'calculates correctly for 240 second exclusion' do
        payload['time'] = 300000  # 5:00
        payload['duration'] = 240

        result = described_class.apply!(acc, event)
        player_status = result['player_status']['123']

        expect(player_status[:until_time]).to eq(60000)  # 1:00
      end
    end
  end

  describe '.timeline' do
    let(:payload) do
      {
        'primary_player_id' => '123',
        'duration' => 20,
        'reason' => 'ordinary_foul',
        'time' => 90000,
        'period' => 2
      }
    end

    it 'returns timeline hash' do
      result = described_class.timeline(event)
      expect(result).to be_a(Hash)
      expect(result).to include(:text, :icon, :color, :timestamp)
    end

    it 'includes player and duration in text' do
      result = described_class.timeline(event)
      expect(result[:text]).to include('123')
      expect(result[:text]).to include('20s')
    end

    it 'includes reason in text' do
      result = described_class.timeline(event)
      expect(result[:text]).to include('Ordinary foul')
    end

    it 'includes time and period' do
      result = described_class.timeline(event)
      expect(result[:text]).to include('1:30')
      expect(result[:text]).to include('Q2')
    end

    it 'uses ejection icon' do
      result = described_class.timeline(event)
      expect(result[:icon]).to eq('🚫')
    end

    it 'uses red color' do
      result = described_class.timeline(event)
      expect(result[:color]).to eq('red')
    end
  end
end
