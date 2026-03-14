# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveReappraisal::Helpers::EmotionalEvent do
  subject(:event) do
    described_class.new(
      content:   'test event',
      valence:   -0.6,
      intensity: 0.5,
      appraisal: 'threatening situation'
    )
  end

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(event.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores content' do
      expect(event.content).to eq('test event')
    end

    it 'stores initial_valence clamped to -1..1' do
      e = described_class.new(content: 'x', valence: -2.0, intensity: 0.5, appraisal: 'a')
      expect(e.initial_valence).to eq(-1.0)
    end

    it 'stores initial_intensity clamped to 0..1' do
      e = described_class.new(content: 'x', valence: 0.0, intensity: 1.5, appraisal: 'a')
      expect(e.initial_intensity).to eq(1.0)
    end

    it 'sets current_valence equal to initial_valence' do
      expect(event.current_valence).to eq(event.initial_valence)
    end

    it 'sets current_intensity equal to initial_intensity' do
      expect(event.current_intensity).to eq(event.initial_intensity)
    end

    it 'starts with reappraisal_count 0' do
      expect(event.reappraisal_count).to eq(0)
    end

    it 'sets created_at to a Time' do
      expect(event.created_at).to be_a(Time)
    end
  end

  describe '#reappraise!' do
    it 'increases valence toward positive' do
      before = event.current_valence
      event.reappraise!(strategy: :reinterpretation, new_appraisal: 'challenge')
      expect(event.current_valence).to be > before
    end

    it 'reduces intensity' do
      before = event.current_intensity
      event.reappraise!(strategy: :reinterpretation, new_appraisal: 'challenge')
      expect(event.current_intensity).to be < before
    end

    it 'increments reappraisal_count' do
      expect { event.reappraise!(strategy: :distancing, new_appraisal: 'distant') }
        .to change(event, :reappraisal_count).by(1)
    end

    it 'updates appraisal text' do
      event.reappraise!(strategy: :benefit_finding, new_appraisal: 'growth opportunity')
      expect(event.appraisal).to eq('growth opportunity')
    end

    it 'returns amount of change as a Float' do
      change = event.reappraise!(strategy: :reinterpretation, new_appraisal: 'new view')
      expect(change).to be_a(Float)
      expect(change).to be >= 0.0
    end

    it 'returns 0.0 for invalid strategy' do
      change = event.reappraise!(strategy: :nonexistent, new_appraisal: 'irrelevant')
      expect(change).to eq(0.0)
    end

    it 'applies difficulty multiplier for high-intensity events' do
      high = described_class.new(content: 'x', valence: -0.8, intensity: 0.9, appraisal: 'bad')
      low  = described_class.new(content: 'x', valence: -0.8, intensity: 0.3, appraisal: 'bad')

      high_change = high.reappraise!(strategy: :reinterpretation, new_appraisal: 'reframed')
      low_change  = low.reappraise!(strategy: :reinterpretation, new_appraisal: 'reframed')

      expect(high_change).to be < low_change
    end

    it 'does not allow valence to exceed 1.0' do
      e = described_class.new(content: 'x', valence: 0.95, intensity: 0.1, appraisal: 'ok')
      10.times { e.reappraise!(strategy: :reinterpretation, new_appraisal: 'great') }
      expect(e.current_valence).to be <= 1.0
    end

    it 'does not allow intensity to go below 0.0' do
      e = described_class.new(content: 'x', valence: -0.5, intensity: 0.05, appraisal: 'bad')
      10.times { e.reappraise!(strategy: :reinterpretation, new_appraisal: 'better') }
      expect(e.current_intensity).to be >= 0.0
    end
  end

  describe '#negative?' do
    it 'returns true when current_valence is below threshold' do
      expect(event.negative?).to be true
    end

    it 'returns false for positive valence' do
      e = described_class.new(content: 'x', valence: 0.5, intensity: 0.3, appraisal: 'good')
      expect(e.negative?).to be false
    end
  end

  describe '#intense?' do
    it 'returns false for moderate intensity' do
      expect(event.intense?).to be false
    end

    it 'returns true for high intensity' do
      e = described_class.new(content: 'x', valence: -0.5, intensity: 0.8, appraisal: 'bad')
      expect(e.intense?).to be true
    end
  end

  describe '#regulation_amount' do
    it 'returns 0.0 for unmodified event' do
      expect(event.regulation_amount).to eq(0.0)
    end

    it 'returns positive value after reappraisal' do
      event.reappraise!(strategy: :reinterpretation, new_appraisal: 'changed')
      expect(event.regulation_amount).to be > 0.0
    end

    it 'returns value between 0 and 1' do
      event.reappraise!(strategy: :reinterpretation, new_appraisal: 'changed')
      expect(event.regulation_amount).to be_between(0.0, 1.0)
    end
  end

  describe '#valence_label' do
    it 'returns :negative for valence -0.6' do
      expect(event.valence_label).to eq(:negative)
    end

    it 'returns :positive after positive reappraisals' do
      e = described_class.new(content: 'x', valence: 0.7, intensity: 0.3, appraisal: 'good')
      expect(e.valence_label).to eq(:positive)
    end
  end

  describe '#intensity_label' do
    it 'returns :moderate for intensity 0.5' do
      expect(event.intensity_label).to eq(:moderate)
    end
  end

  describe '#to_h' do
    it 'returns a hash with all expected keys' do
      h = event.to_h
      expect(h).to include(:id, :content, :initial_valence, :current_valence,
                           :initial_intensity, :current_intensity, :appraisal,
                           :reappraisal_count, :negative, :intense,
                           :regulation_amount, :valence_label, :intensity_label, :created_at)
    end

    it 'reflects updated state after reappraisal' do
      event.reappraise!(strategy: :benefit_finding, new_appraisal: 'growth')
      h = event.to_h
      expect(h[:reappraisal_count]).to eq(1)
      expect(h[:appraisal]).to eq('growth')
    end
  end
end
