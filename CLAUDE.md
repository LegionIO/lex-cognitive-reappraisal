# lex-cognitive-reappraisal

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Cognitive reappraisal extension for the LegionIO cognitive architecture. Implements James Gross's process model of emotion regulation — the ability to re-interpret emotional events to change their emotional impact before the full emotional response unfolds. Cognitive reappraisal is the most empirically supported emotion regulation strategy.

## Gem Info

- **Gem name**: `lex-cognitive-reappraisal`
- **Version**: `0.1.0`
- **Module**: `Legion::Extensions::CognitiveReappraisal`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/cognitive_reappraisal/
  version.rb
  helpers/
    constants.rb          # STRATEGIES, STRATEGY_EFFECTIVENESS, label maps, thresholds, utility functions
    emotional_event.rb    # EmotionalEvent class - valence, intensity, reappraise!, labels, to_h
    reappraisal_engine.rb # ReappraisalEngine class - event registry, reappraisal log, analytics
  runners/
    cognitive_reappraisal.rb  # register_event, reappraise_event, auto_reappraise_event,
                              # negative_events, intense_events, most_regulated_events,
                              # reappraisal_status, reappraisal_report
spec/
  legion/extensions/cognitive_reappraisal/
    helpers/
      constants_spec.rb
      emotional_event_spec.rb
      reappraisal_engine_spec.rb
    runners/
      cognitive_reappraisal_spec.rb
    client_spec.rb
```

## Key Constants (Helpers::Constants)

```ruby
STRATEGIES = %i[reinterpretation distancing benefit_finding normalizing perspective_taking temporal_distancing]

STRATEGY_EFFECTIVENESS = {
  reinterpretation:    0.25,   # Re-frame meaning
  benefit_finding:     0.20,   # Find positive outcomes
  perspective_taking:  0.18,   # Adopt another viewpoint
  distancing:          0.15,   # Psychological distance
  normalizing:         0.12,   # Recognize as common
  temporal_distancing: 0.10    # Future-self projection
}

NEGATIVE_VALENCE_THRESHOLD       = -0.3   # below this = negative event
HIGH_INTENSITY_THRESHOLD         = 0.7    # above this = intense event (harder to reappraise)
REAPPRAISAL_DIFFICULTY_MULTIPLIER = 0.5   # high intensity halves effectiveness
```

## EmotionalEvent Class

- `initial_valence` / `current_valence`: float -1..1 (negative = aversive, positive = pleasant)
- `initial_intensity` / `current_intensity`: float 0..1 (how activating the event is)
- `appraisal`: string interpretation of the event (updated by reappraisal)
- `reappraise!(strategy:, new_appraisal:)`: adjusts valence toward positive by `STRATEGY_EFFECTIVENESS[strategy]`, reduces intensity by 50% of effectiveness. Returns total change amount. High initial intensity (`> HIGH_INTENSITY_THRESHOLD`) applies the 0.5 difficulty multiplier.
- `regulation_amount`: normalized 0..1 composite of `|valence_change| + |intensity_change| / 2`

## ReappraisalEngine Class

- `@events`: Hash by id of EmotionalEvent instances (capped at MAX_EVENTS=300)
- `@reappraisal_log`: Array of log entries `{event_id, strategy, valence_change, intensity_change, applied_at}` (capped at MAX_REAPPRAISALS=500)
- `auto_reappraise(event_id:)`: selects strategy based on event characteristics:
  - negative + intense -> `:distancing`
  - negative only -> `:reinterpretation`
  - intense only -> `:temporal_distancing`
  - otherwise -> `:benefit_finding`
- `strategy_effectiveness`: returns per-strategy average valence_change from log
- `overall_regulation_ability`: composite of mean regulation_amount and coverage fraction

## Integration Points

- **lex-tick**: `emotional_regulation` phase (not yet wired in PHASE_MAP — future extension)
- **lex-emotion**: valence output from `evaluate_valence` feeds `register_event`; regulated valence feeds back into emotional state
- **lex-memory**: reappraisal outcomes can be stored as episodic traces

## Development Notes

- Valence is on a -1..1 scale (unlike lex-emotion dimensions which are 0..1 per dimension)
- Intensity is 0..1; high intensity makes reappraisal harder — models empirical finding that overwhelming emotions resist reappraisal
- `engine:` kwarg on all runners enables dependency injection in tests (avoids memoized state bleed)
- All floating point values use `.round(10)` for deterministic equality in specs
