# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveReappraisal::Helpers::ReappraisalEngine do
  subject(:engine) { described_class.new }

  let(:neg_event_id) do
    engine.register_event(content: 'failure', valence: -0.7, intensity: 0.4, appraisal: 'terrible').id
  end

  let(:pos_event_id) do
    engine.register_event(content: 'success', valence: 0.6, intensity: 0.3, appraisal: 'great').id
  end

  describe '#register_event' do
    it 'returns an EmotionalEvent' do
      event = engine.register_event(content: 'test', valence: -0.5, intensity: 0.4, appraisal: 'bad')
      expect(event).to be_a(Legion::Extensions::CognitiveReappraisal::Helpers::EmotionalEvent)
    end

    it 'stores the event by id' do
      event = engine.register_event(content: 'test', valence: -0.5, intensity: 0.4, appraisal: 'bad')
      expect(engine.events[event.id]).to eq(event)
    end

    it 'increments event count' do
      expect { engine.register_event(content: 'x', valence: 0.0, intensity: 0.5, appraisal: 'neutral') }
        .to change { engine.events.size }.by(1)
    end
  end

  describe '#reappraise' do
    it 'returns success for valid inputs' do
      result = engine.reappraise(event_id: neg_event_id, strategy: :reinterpretation, new_appraisal: 'reframed')
      expect(result[:success]).to be true
    end

    it 'returns event_id and strategy in response' do
      result = engine.reappraise(event_id: neg_event_id, strategy: :distancing, new_appraisal: 'distant view')
      expect(result[:event_id]).to eq(neg_event_id)
      expect(result[:strategy]).to eq(:distancing)
    end

    it 'returns current_valence after reappraisal' do
      result = engine.reappraise(event_id: neg_event_id, strategy: :benefit_finding, new_appraisal: 'learned')
      expect(result[:current_valence]).to be_a(Float)
    end

    it 'fails with :event_not_found for unknown id' do
      result = engine.reappraise(event_id: 'unknown-id', strategy: :reinterpretation, new_appraisal: 'x')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:event_not_found)
    end

    it 'fails with :invalid_strategy for bad strategy' do
      result = engine.reappraise(event_id: neg_event_id, strategy: :magic, new_appraisal: 'x')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:invalid_strategy)
    end

    it 'logs the reappraisal in reappraisal_log' do
      engine.reappraise(event_id: neg_event_id, strategy: :normalizing, new_appraisal: 'normal')
      expect(engine.reappraisal_log.size).to eq(1)
      expect(engine.reappraisal_log.first[:strategy]).to eq(:normalizing)
    end

    it 'records valence_change and intensity_change in log' do
      engine.reappraise(event_id: neg_event_id, strategy: :reinterpretation, new_appraisal: 'changed')
      log = engine.reappraisal_log.first
      expect(log[:valence_change]).to be_a(Float)
      expect(log[:intensity_change]).to be_a(Float)
    end
  end

  describe '#auto_reappraise' do
    it 'succeeds for a valid event' do
      result = engine.auto_reappraise(event_id: neg_event_id)
      expect(result[:success]).to be true
    end

    it 'selects distancing for intense negative event' do
      intense_neg_id = engine.register_event(content: 'crisis', valence: -0.8, intensity: 0.9, appraisal: 'worst').id
      result = engine.auto_reappraise(event_id: intense_neg_id)
      expect(result[:strategy]).to eq(:distancing)
    end

    it 'selects reinterpretation for non-intense negative event' do
      result = engine.auto_reappraise(event_id: neg_event_id)
      expect(result[:strategy]).to eq(:reinterpretation)
    end

    it 'selects benefit_finding for mild positive events' do
      result = engine.auto_reappraise(event_id: pos_event_id)
      expect(result[:strategy]).to eq(:benefit_finding)
    end

    it 'fails for unknown event_id' do
      result = engine.auto_reappraise(event_id: 'missing')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:event_not_found)
    end
  end

  describe '#negative_events' do
    it 'returns events with negative current_valence' do
      neg_event_id
      pos_event_id
      expect(engine.negative_events.size).to eq(1)
      expect(engine.negative_events.first.negative?).to be true
    end

    it 'returns empty array when no negative events' do
      pos_event_id
      expect(engine.negative_events).to be_empty
    end
  end

  describe '#intense_events' do
    it 'returns events with high intensity' do
      engine.register_event(content: 'crisis', valence: -0.8, intensity: 0.9, appraisal: 'worst')
      engine.register_event(content: 'calm', valence: 0.2, intensity: 0.2, appraisal: 'fine')
      expect(engine.intense_events.size).to eq(1)
    end
  end

  describe '#most_regulated' do
    before do
      # Register two events and reappraise one multiple times
      @event_a_id = engine.register_event(content: 'a', valence: -0.6, intensity: 0.4, appraisal: 'bad').id
      @event_b_id = engine.register_event(content: 'b', valence: -0.4, intensity: 0.3, appraisal: 'ok').id
      3.times { engine.reappraise(event_id: @event_a_id, strategy: :reinterpretation, new_appraisal: 'better') }
    end

    it 'returns events sorted by regulation_amount descending' do
      regulated = engine.most_regulated(limit: 2)
      expect(regulated.first.id).to eq(@event_a_id)
    end

    it 'respects limit parameter' do
      expect(engine.most_regulated(limit: 1).size).to eq(1)
    end
  end

  describe '#strategy_effectiveness' do
    before do
      engine.reappraise(event_id: neg_event_id, strategy: :reinterpretation, new_appraisal: 'view 1')
      engine.reappraise(event_id: neg_event_id, strategy: :reinterpretation, new_appraisal: 'view 2')
      engine.reappraise(event_id: neg_event_id, strategy: :distancing, new_appraisal: 'distant')
    end

    it 'returns a hash keyed by strategy' do
      eff = engine.strategy_effectiveness
      expect(eff).to have_key(:reinterpretation)
      expect(eff).to have_key(:distancing)
    end

    it 'computes average valence_change per strategy' do
      eff = engine.strategy_effectiveness
      expect(eff[:reinterpretation]).to be_a(Float)
    end
  end

  describe '#average_regulation' do
    it 'returns 0.0 for empty engine' do
      expect(engine.average_regulation).to eq(0.0)
    end

    it 'returns positive value after events and reappraisals' do
      neg_event_id
      engine.reappraise(event_id: neg_event_id, strategy: :reinterpretation, new_appraisal: 'better')
      expect(engine.average_regulation).to be > 0.0
    end
  end

  describe '#overall_regulation_ability' do
    it 'returns 0.0 for empty engine' do
      expect(engine.overall_regulation_ability).to eq(0.0)
    end

    it 'returns value between 0 and 1' do
      neg_event_id
      engine.reappraise(event_id: neg_event_id, strategy: :benefit_finding, new_appraisal: 'learned')
      expect(engine.overall_regulation_ability).to be_between(0.0, 1.0)
    end
  end

  describe '#reappraisal_report' do
    it 'returns a hash with all expected keys' do
      report = engine.reappraisal_report
      expect(report).to include(:total_events, :total_reappraisals, :negative_events,
                                :intense_events, :average_regulation,
                                :overall_regulation_ability, :strategy_effectiveness, :most_regulated)
    end

    it 'reflects actual counts' do
      neg_event_id
      pos_event_id
      engine.reappraise(event_id: neg_event_id, strategy: :normalizing, new_appraisal: 'normal')
      report = engine.reappraisal_report
      expect(report[:total_events]).to eq(2)
      expect(report[:total_reappraisals]).to eq(1)
    end
  end

  describe '#to_h' do
    it 'returns a hash with expected keys' do
      h = engine.to_h
      expect(h).to include(:events, :reappraisal_log, :average_regulation,
                           :overall_regulation_ability, :strategy_effectiveness)
    end
  end
end
