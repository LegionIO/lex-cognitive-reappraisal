# frozen_string_literal: true

require 'legion/extensions/cognitive_reappraisal/client'

RSpec.describe Legion::Extensions::CognitiveReappraisal::Client do
  it 'responds to all runner methods' do
    client = described_class.new
    expect(client).to respond_to(:register_event)
    expect(client).to respond_to(:reappraise_event)
    expect(client).to respond_to(:auto_reappraise_event)
    expect(client).to respond_to(:negative_events)
    expect(client).to respond_to(:intense_events)
    expect(client).to respond_to(:most_regulated_events)
    expect(client).to respond_to(:reappraisal_status)
    expect(client).to respond_to(:reappraisal_report)
  end

  it 'accepts an injected engine' do
    engine = Legion::Extensions::CognitiveReappraisal::Helpers::ReappraisalEngine.new
    client = described_class.new(engine: engine)
    result = client.register_event(
      content:   'injected test',
      valence:   -0.5,
      intensity: 0.4,
      appraisal: 'difficult',
      engine:    engine
    )
    expect(result[:success]).to be true
    expect(engine.events.size).to eq(1)
  end

  it 'creates its own engine when none injected' do
    client = described_class.new
    result = client.register_event(
      content:   'standalone test',
      valence:   0.3,
      intensity: 0.2,
      appraisal: 'fine'
    )
    expect(result[:success]).to be true
  end

  it 'executes a full register -> reappraise -> report cycle' do
    client = described_class.new
    reg    = client.register_event(
      content:   'system alert',
      valence:   -0.6,
      intensity: 0.6,
      appraisal: 'unrecoverable failure'
    )
    expect(reg[:success]).to be true

    reap = client.reappraise_event(
      event_id:      reg[:event_id],
      strategy:      :temporal_distancing,
      new_appraisal: 'this will be a minor footnote in six months'
    )
    expect(reap[:success]).to be true

    report = client.reappraisal_report
    expect(report[:report][:total_events]).to eq(1)
    expect(report[:report][:total_reappraisals]).to eq(1)
  end
end
