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

- **lex-tick**: `emotional_regulation` phase
- **lex-emotion**: valence output feeds reappraisal input; regulated valence feeds back
- **lex-memory**: reappraisal outcomes stored as episodic traces

## License

MIT
