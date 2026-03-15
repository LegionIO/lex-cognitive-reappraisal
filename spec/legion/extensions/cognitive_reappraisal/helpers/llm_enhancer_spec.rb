# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveReappraisal::Helpers::LlmEnhancer do
  subject(:enhancer) { described_class }

  describe '.available?' do
    context 'when Legion::LLM is not defined' do
      it 'returns false' do
        expect(enhancer.available?).to be false
      end
    end

    context 'when Legion::LLM is defined but not started' do
      before do
        stub_const('Legion::LLM', double(respond_to?: true, started?: false))
      end

      it 'returns false' do
        expect(enhancer.available?).to be false
      end
    end

    context 'when Legion::LLM is started' do
      before do
        stub_const('Legion::LLM', double(respond_to?: true, started?: true))
      end

      it 'returns true' do
        expect(enhancer.available?).to be true
      end
    end

    context 'when Legion::LLM raises an error' do
      before do
        stub_const('Legion::LLM', double)
        allow(Legion::LLM).to receive(:respond_to?).and_raise(StandardError, 'boom')
      end

      it 'returns false' do
        expect(enhancer.available?).to be false
      end
    end
  end

  describe '.generate_reappraisal' do
    let(:mock_response) do
      content = "REAPPRAISAL: This outage is an opportunity to strengthen the system's resilience and learn " \
                'from the failure patterns that emerged under load.'
      double('response', content: content)
    end

    before do
      stub_const('Legion::LLM', double)
      chat = double('chat')
      allow(Legion::LLM).to receive(:chat).and_return(chat)
      allow(chat).to receive(:with_instructions)
      allow(chat).to receive(:ask).and_return(mock_response)
    end

    it 'returns a hash with new_appraisal' do
      result = enhancer.generate_reappraisal(
        event_content:     'production outage',
        initial_appraisal: 'catastrophic failure',
        strategy:          :benefit_finding,
        valence:           -0.7,
        intensity:         0.5
      )
      expect(result).to be_a(Hash)
      expect(result[:new_appraisal]).to be_a(String)
      expect(result[:new_appraisal]).not_to be_empty
    end

    it 'strips leading/trailing whitespace from the reappraisal' do
      result = enhancer.generate_reappraisal(
        event_content:     'production outage',
        initial_appraisal: 'catastrophic failure',
        strategy:          :benefit_finding,
        valence:           -0.7,
        intensity:         0.5
      )
      expect(result[:new_appraisal]).to eq(result[:new_appraisal].strip)
    end

    context 'when LLM raises an error' do
      before do
        chat = double('chat')
        allow(Legion::LLM).to receive(:chat).and_return(chat)
        allow(chat).to receive(:with_instructions)
        allow(chat).to receive(:ask).and_raise(StandardError, 'API error')
      end

      it 'returns nil' do
        result = enhancer.generate_reappraisal(
          event_content:     'test event',
          initial_appraisal: 'bad',
          strategy:          :reinterpretation,
          valence:           -0.5,
          intensity:         0.4
        )
        expect(result).to be_nil
      end
    end

    context 'when response has no content' do
      before do
        chat = double('chat')
        allow(Legion::LLM).to receive(:chat).and_return(chat)
        allow(chat).to receive(:with_instructions)
        allow(chat).to receive(:ask).and_return(double('response', content: nil))
      end

      it 'returns nil' do
        result = enhancer.generate_reappraisal(
          event_content:     'test',
          initial_appraisal: 'test',
          strategy:          :distancing,
          valence:           -0.3,
          intensity:         0.5
        )
        expect(result).to be_nil
      end
    end

    context 'when response lacks REAPPRAISAL marker' do
      before do
        bad_response = double('response', content: 'Just some text without the format marker.')
        chat = double('chat')
        allow(Legion::LLM).to receive(:chat).and_return(chat)
        allow(chat).to receive(:with_instructions)
        allow(chat).to receive(:ask).and_return(bad_response)
      end

      it 'returns nil' do
        result = enhancer.generate_reappraisal(
          event_content:     'test',
          initial_appraisal: 'test',
          strategy:          :normalizing,
          valence:           -0.4,
          intensity:         0.3
        )
        expect(result).to be_nil
      end
    end

    context 'with different strategies' do
      %i[reinterpretation distancing benefit_finding normalizing perspective_taking temporal_distancing].each do |strategy|
        it "works with strategy #{strategy}" do
          result = enhancer.generate_reappraisal(
            event_content:     'a difficult situation',
            initial_appraisal: 'overwhelming',
            strategy:          strategy,
            valence:           -0.6,
            intensity:         0.7
          )
          expect(result).to be_a(Hash)
          expect(result[:new_appraisal]).to be_a(String)
        end
      end
    end
  end
end
