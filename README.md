# lex-cognitive-reappraisal

Cognitive reappraisal extension for [LegionIO](https://github.com/LegionIO). Implements James Gross's process model of emotion regulation — the ability to re-interpret emotional events to change their emotional impact before the full response unfolds.

## What It Models

Cognitive reappraisal is the most empirically supported emotion regulation strategy. This extension models:

- **EmotionalEvent**: A stimulus with initial valence (-1 to 1), intensity (0-1), and an interpretation (appraisal)
- **Six ReappraisalStrategies**: reinterpretation, distancing, benefit_finding, normalizing, perspective_taking, temporal_distancing
- **ReappraisalEngine**: Processes events, applies strategies, tracks effectiveness per strategy over time

## Installation

Add to your Gemfile:

```ruby
gem 'lex-cognitive-reappraisal'
```

## Usage

```ruby
client = Legion::Extensions::CognitiveReappraisal::Client.new

result = client.register_event(
  content:   'critical system failure detected',
  valence:   -0.8,
  intensity: 0.9,
  appraisal: 'catastrophic and unrecoverable'
)

client.reappraise_event(
  event_id:      result[:event_id],
  strategy:      :reinterpretation,
  new_appraisal: 'an opportunity to improve system resilience'
)

client.reappraisal_report
```

## Strategies

| Strategy             | Base Effectiveness | Description                                      |
|----------------------|--------------------|--------------------------------------------------|
| reinterpretation     | 0.25               | Re-frame the meaning of the event               |
| benefit_finding      | 0.20               | Identify positive outcomes or growth potential  |
| perspective_taking   | 0.18               | Adopt another viewpoint                         |
| distancing           | 0.15               | Create psychological distance from the event    |
| normalizing          | 0.12               | Recognize the event as common or expected       |
| temporal_distancing  | 0.10               | Consider how you'll feel about this in the future |

High-intensity events (> 0.7) reduce reappraisal effectiveness by 50% (difficulty multiplier).

## Integration

- **lex-emotion**: valence output from `evaluate_valence` feeds reappraisal input; regulated valence feeds back into emotional state
- **lex-memory**: reappraisal outcomes can be stored as episodic traces
- **lex-tick**: not currently in lex-cortex's PHASE_MAP — must be called manually from `action_selection` or post-emotional-evaluation hooks

## Actors

| Actor | Interval | Description |
|-------|----------|-------------|
| `AutoRegulate` | Every 300s | Scans all registered events and auto-reappraises any that are negative and have not yet received any reappraisal (`reappraisal_count.zero?`). Strategy selection follows the heuristic: negative + intense -> `:distancing`, negative only -> `:reinterpretation`, intense only -> `:temporal_distancing`, otherwise -> `:benefit_finding`. |

## LLM Enhancement

`Helpers::LlmEnhancer` provides optional LLM-powered reappraisal text generation when `legion-llm` is loaded and `Legion::LLM.started?` returns true. All methods rescue `StandardError` and return `nil` — callers always fall back to mechanical processing.

| Method | Description |
|--------|-------------|
| `generate_reappraisal(event_content:, initial_appraisal:, strategy:, valence:, intensity:)` | Generates a strategy-aware, psychologically-grounded 1-2 sentence re-framing of the event using the specified strategy. Includes the original event content, current appraisal, valence, and intensity so the LLM can produce a contextually specific reappraisal. |

Mechanical fallback: `reappraise_event` and `auto_reappraise_event` fall back to `"auto-reappraised via #{strategy}"` as the `new_appraisal` string when LLM is unavailable or returns `nil`.

## License

MIT
