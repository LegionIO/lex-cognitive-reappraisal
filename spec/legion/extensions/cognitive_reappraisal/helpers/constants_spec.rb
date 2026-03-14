# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveReappraisal::Helpers::Constants do
  describe 'STRATEGIES' do
    it 'includes all six strategies' do
      expect(described_class::STRATEGIES).to include(
        :reinterpretation, :distancing, :benefit_finding,
        :normalizing, :perspective_taking, :temporal_distancing
      )
    end

    it 'is frozen' do
      expect(described_class::STRATEGIES).to be_frozen
    end
  end

  describe 'STRATEGY_EFFECTIVENESS' do
    it 'has an entry for every strategy' do
      described_class::STRATEGIES.each do |s|
        expect(described_class::STRATEGY_EFFECTIVENESS).to have_key(s)
      end
    end

    it 'rates reinterpretation highest' do
      expect(described_class::STRATEGY_EFFECTIVENESS[:reinterpretation]).to be >
                                                                            described_class::STRATEGY_EFFECTIVENESS[:temporal_distancing]
    end

    it 'all effectiveness values are between 0 and 1' do
      described_class::STRATEGY_EFFECTIVENESS.each_value do |v|
        expect(v).to be_between(0.0, 1.0)
      end
    end
  end

  describe '.valid_strategy?' do
    it 'returns true for valid strategies' do
      expect(described_class.valid_strategy?(:reinterpretation)).to be true
      expect(described_class.valid_strategy?(:distancing)).to be true
    end

    it 'returns false for unknown strategy' do
      expect(described_class.valid_strategy?(:nonexistent)).to be false
    end
  end

  describe '.label_for' do
    it 'returns :positive for valence 0.8' do
      expect(described_class.label_for(0.8, described_class::VALENCE_LABELS)).to eq(:positive)
    end

    it 'returns :negative for valence -0.8' do
      expect(described_class.label_for(-0.8, described_class::VALENCE_LABELS)).to eq(:negative)
    end

    it 'returns :neutral for valence 0.0' do
      expect(described_class.label_for(0.0, described_class::VALENCE_LABELS)).to eq(:neutral)
    end

    it 'returns :overwhelming for intensity 0.9' do
      expect(described_class.label_for(0.9, described_class::INTENSITY_LABELS)).to eq(:overwhelming)
    end

    it 'returns :faint for intensity 0.1' do
      expect(described_class.label_for(0.1, described_class::INTENSITY_LABELS)).to eq(:faint)
    end

    it 'returns :excellent for regulation 0.9' do
      expect(described_class.label_for(0.9, described_class::REGULATION_LABELS)).to eq(:excellent)
    end
  end

  describe '.clamp' do
    it 'clamps to -1..1 by default' do
      expect(described_class.clamp(2.0)).to eq(1.0)
      expect(described_class.clamp(-2.0)).to eq(-1.0)
      expect(described_class.clamp(0.5)).to eq(0.5)
    end
  end

  describe '.clamp_intensity' do
    it 'clamps to 0..1' do
      expect(described_class.clamp_intensity(1.5)).to eq(1.0)
      expect(described_class.clamp_intensity(-0.1)).to eq(0.0)
      expect(described_class.clamp_intensity(0.7)).to eq(0.7)
    end
  end

  describe 'thresholds' do
    it 'defines NEGATIVE_VALENCE_THRESHOLD' do
      expect(described_class::NEGATIVE_VALENCE_THRESHOLD).to eq(-0.3)
    end

    it 'defines HIGH_INTENSITY_THRESHOLD' do
      expect(described_class::HIGH_INTENSITY_THRESHOLD).to eq(0.7)
    end

    it 'defines REAPPRAISAL_DIFFICULTY_MULTIPLIER' do
      expect(described_class::REAPPRAISAL_DIFFICULTY_MULTIPLIER).to eq(0.5)
    end
  end
end
