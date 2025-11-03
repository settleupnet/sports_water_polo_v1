# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SportsWaterPoloV1::Strategies::WonSprint do
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
          'time' => 480000,
          'period' => 1
        }
      end

      it 'returns true' do
        expect(described_class.validate!(payload)).to be true
      end
    end

    context 'with missing primary_player_id' do
      let(:payload) do
        {
          'time' => 480000
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
        'time' => 480000,
        'period' => 1
      }
    end

    context 'with empty accumulator' do
      let(:acc) { {} }

      it 'initializes sprints_won hash' do
        result = described_class.apply!(acc, event)
        expect(result['sprints_won']).to be_a(Hash)
        expect(result['sprints_won']['us']).to eq(1)
        expect(result['sprints_won']['them']).to eq(0)
      end

      it 'initializes sprint_events array' do
        result = described_class.apply!(acc, event)
        expect(result['sprint_events']).to be_an(Array)
        expect(result['sprint_events'].size).to eq(1)
      end

      it 'records sprint details' do
        result = described_class.apply!(acc, event)
        sprint = result['sprint_events'].first

        expect(sprint[:id]).to eq(1)
        expect(sprint[:side]).to eq('us')
        expect(sprint[:winner_id]).to eq('123')
        expect(sprint[:time]).to eq(480000)
        expect(sprint[:period]).to eq(1)
        expect(sprint[:seq]).to eq(1)
      end
    end
  end

  describe '.timeline' do
    let(:payload) do
      {
        'primary_player_id' => '123',
        'time' => 480000,
        'period' => 1
      }
    end

    it 'returns timeline hash' do
      result = described_class.timeline(event)
      expect(result).to be_a(Hash)
      expect(result).to include(:text, :icon, :color, :timestamp)
    end

    it 'includes winner in text' do
      result = described_class.timeline(event)
      expect(result[:text]).to include('123')
      expect(result[:text]).to include('wins sprint')
    end

    it 'uses swimmer icon' do
      result = described_class.timeline(event)
      expect(result[:icon]).to eq('🏊')
    end

    it 'uses green color' do
      result = described_class.timeline(event)
      expect(result[:color]).to eq('green')
    end
  end
end
