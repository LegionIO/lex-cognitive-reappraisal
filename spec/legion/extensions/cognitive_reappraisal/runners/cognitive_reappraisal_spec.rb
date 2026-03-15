# frozen_string_literal: true

require 'legion/extensions/cognitive_reappraisal/client'

RSpec.describe Legion::Extensions::CognitiveReappraisal::Runners::CognitiveReappraisal do
  let(:engine) { Legion::Extensions::CognitiveReappraisal::Helpers::ReappraisalEngine.new }
  let(:client) { Legion::Extensions::CognitiveReappraisal::Client.new(engine: engine) }

  let(:registered) do
    client.register_event(
      content:   'production outage',
      valence:   -0.7,
      intensity: 0.5,
      appraisal: 'catastrophic failure',
      engine:    engine
    )
  end

  describe '#register_event' do
    it 'returns success: true' do
      expect(registered[:success]).to be true
    end

    it 'returns a valid UUID event_id' do
      expect(registered[:event_id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'returns valence and intensity' do
      expect(registered[:valence]).to be_a(Float)
      expect(registered[:intensity]).to be_a(Float)
    end

    it 'reports negative: true for negative event' do
      expect(registered[:negative]).to be true
    end

    it 'reports intense: false for moderate intensity' do
      expect(registered[:intense]).to be false
    end

    it 'reports intense: true for high intensity' do
      result = client.register_event(
        content: 'extreme', valence: -0.9, intensity: 0.9, appraisal: 'worst', engine: engine
      )
      expect(result[:intense]).to be true
    end
  end

  describe '#reappraise_event' do
    it 'succeeds with valid event_id and strategy' do
      result = client.reappraise_event(
        event_id:      registered[:event_id],
        strategy:      :reinterpretation,
        new_appraisal: 'learning opportunity',
        engine:        engine
      )
      expect(result[:success]).to be true
    end

    it 'returns current_valence after reappraisal' do
      result = client.reappraise_event(
        event_id:      registered[:event_id],
        strategy:      :benefit_finding,
        new_appraisal: 'builds resilience',
        engine:        engine
      )
      expect(result[:current_valence]).to be_a(Float)
    end

    it 'rejects invalid strategy' do
      result = client.reappraise_event(
        event_id:      registered[:event_id],
        strategy:      :magic_thinking,
        new_appraisal: 'irrelevant',
        engine:        engine
      )
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:invalid_strategy)
      expect(result[:valid_strategies]).to eq(Legion::Extensions::CognitiveReappraisal::Helpers::Constants::STRATEGIES)
    end

    it 'rejects unknown event_id' do
      result = client.reappraise_event(
        event_id:      'does-not-exist',
        strategy:      :distancing,
        new_appraisal: 'distant',
        engine:        engine
      )
      expect(result[:success]).to be false
    end
  end

  describe '#auto_reappraise_event' do
    it 'succeeds for a known event' do
      result = client.auto_reappraise_event(event_id: registered[:event_id], engine: engine)
      expect(result[:success]).to be true
    end

    it 'selects an appropriate strategy automatically' do
      result = client.auto_reappraise_event(event_id: registered[:event_id], engine: engine)
      expect(Legion::Extensions::CognitiveReappraisal::Helpers::Constants::STRATEGIES).to include(result[:strategy])
    end

    it 'fails gracefully for unknown event' do
      result = client.auto_reappraise_event(event_id: 'missing', engine: engine)
      expect(result[:success]).to be false
    end
  end

  describe '#negative_events' do
    before { registered }

    it 'returns count and events array' do
      result = client.negative_events(engine: engine)
      expect(result).to have_key(:events)
      expect(result).to have_key(:count)
    end

    it 'includes the registered negative event' do
      result = client.negative_events(engine: engine)
      expect(result[:count]).to be >= 1
    end
  end

  describe '#intense_events' do
    it 'returns empty when no intense events' do
      registered
      result = client.intense_events(engine: engine)
      expect(result[:count]).to eq(0)
    end

    it 'returns intense events when present' do
      client.register_event(content: 'crisis', valence: -0.9, intensity: 0.95, appraisal: 'awful', engine: engine)
      result = client.intense_events(engine: engine)
      expect(result[:count]).to be >= 1
    end
  end

  describe '#most_regulated_events' do
    before do
      registered
      3.times do
        client.reappraise_event(
          event_id:      registered[:event_id],
          strategy:      :reinterpretation,
          new_appraisal: 'better each time',
          engine:        engine
        )
      end
    end

    it 'returns events and count' do
      result = client.most_regulated_events(limit: 3, engine: engine)
      expect(result).to have_key(:events)
      expect(result).to have_key(:count)
    end

    it 'respects the limit' do
      result = client.most_regulated_events(limit: 1, engine: engine)
      expect(result[:events].size).to eq(1)
    end
  end

  describe '#reappraisal_status' do
    before { registered }

    it 'returns overall_regulation_ability' do
      result = client.reappraisal_status(engine: engine)
      expect(result).to have_key(:overall_regulation_ability)
    end

    it 'returns total_events count' do
      result = client.reappraisal_status(engine: engine)
      expect(result[:total_events]).to be >= 1
    end

    it 'returns strategy_effectiveness hash' do
      result = client.reappraisal_status(engine: engine)
      expect(result[:strategy_effectiveness]).to be_a(Hash)
    end
  end

  describe '#reappraisal_report' do
    before do
      registered
      client.reappraise_event(
        event_id:      registered[:event_id],
        strategy:      :perspective_taking,
        new_appraisal: 'systemic issue, not personal failure',
        engine:        engine
      )
    end

    it 'returns success: true' do
      result = client.reappraisal_report(engine: engine)
      expect(result[:success]).to be true
    end

    it 'includes a report hash' do
      result = client.reappraisal_report(engine: engine)
      expect(result[:report]).to be_a(Hash)
    end

    it 'report includes total_events and total_reappraisals' do
      result = client.reappraisal_report(engine: engine)
      expect(result[:report][:total_events]).to eq(1)
      expect(result[:report][:total_reappraisals]).to eq(1)
    end
  end

  describe '#regulate_pending_events' do
    it 'returns checked, regulated, and event_ids keys' do
      result = client.regulate_pending_events(engine: engine)
      expect(result).to include(:checked, :regulated, :event_ids)
    end

    it 'returns zero regulated when no events registered' do
      result = client.regulate_pending_events(engine: engine)
      expect(result[:regulated]).to eq(0)
      expect(result[:event_ids]).to eq([])
    end

    it 'regulates negative unreappraisals events' do
      registered
      result = client.regulate_pending_events(engine: engine)
      expect(result[:regulated]).to eq(1)
      expect(result[:event_ids]).to include(registered[:event_id])
    end

    it 'skips events that have already been reappraised' do
      registered
      client.reappraise_event(
        event_id:      registered[:event_id],
        strategy:      :reinterpretation,
        new_appraisal: 'already handled',
        engine:        engine
      )
      result = client.regulate_pending_events(engine: engine)
      expect(result[:regulated]).to eq(0)
    end

    it 'skips positive events' do
      client.register_event(
        content:   'great news',
        valence:   0.8,
        intensity: 0.3,
        appraisal: 'wonderful',
        engine:    engine
      )
      result = client.regulate_pending_events(engine: engine)
      expect(result[:regulated]).to eq(0)
    end

    it 'returns checked equal to total event count' do
      registered
      client.register_event(content: 'another', valence: 0.5, intensity: 0.2, appraisal: 'fine', engine: engine)
      result = client.regulate_pending_events(engine: engine)
      expect(result[:checked]).to eq(2)
    end
  end
end
