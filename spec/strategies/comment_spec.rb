# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SportsWaterPoloV1::Strategies::Comment do
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
          'note' => 'Great defensive play',
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

    context 'with only note' do
      let(:payload) do
        {
          'note' => 'Just a note'
        }
      end

      it 'returns true' do
        expect(described_class.validate!(payload)).to be true
      end
    end
  end

  describe '.apply!' do
    let(:payload) do
      {
        'note' => 'Great defensive play',
        'time' => 240000,
        'period' => 2
      }
    end

    context 'with empty accumulator' do
      let(:acc) { {} }

      it 'initializes comments array' do
        result = described_class.apply!(acc, event)
        expect(result['comments']).to be_an(Array)
        expect(result['comments'].size).to eq(1)
      end

      it 'records comment details' do
        result = described_class.apply!(acc, event)
        comment = result['comments'].first

        expect(comment[:id]).to eq(1)
        expect(comment[:note]).to eq('Great defensive play')
        expect(comment[:time]).to eq(240000)
        expect(comment[:period]).to eq(2)
        expect(comment[:seq]).to eq(1)
      end
    end

    context 'with existing accumulator' do
      let(:acc) do
        {
          'comments' => [
            { id: 0, note: 'First comment', time: 180000, seq: 0 }
          ]
        }
      end

      it 'appends to comments array' do
        result = described_class.apply!(acc, event)
        expect(result['comments'].size).to eq(2)
      end
    end
  end

  describe '.timeline' do
    let(:payload) do
      {
        'note' => 'Great defensive play',
        'time' => 240000,
        'period' => 2
      }
    end

    it 'returns timeline hash' do
      result = described_class.timeline(event)
      expect(result).to be_a(Hash)
      expect(result).to include(:text, :icon, :color, :timestamp)
    end

    it 'uses note as display text' do
      result = described_class.timeline(event)
      expect(result[:text]).to eq('Great defensive play')
    end

    it 'uses default text when note is missing' do
      event_without_note = double('Event', id: 2, side: 'us', payload: {}, seq: 2)
      result = described_class.timeline(event_without_note)
      expect(result[:text]).to eq('Comment')
    end

    it 'uses speech bubble icon' do
      result = described_class.timeline(event)
      expect(result[:icon]).to eq('💬')
    end

    it 'uses gray color' do
      result = described_class.timeline(event)
      expect(result[:color]).to eq('gray')
    end
  end
end
