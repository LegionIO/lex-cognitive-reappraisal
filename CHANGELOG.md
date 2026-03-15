# Changelog

## [0.1.1] - 2026-03-14

### Added
- AutoRegulate periodic actor (Every 300s) — scans all registered events and auto-reappraises any that are negative and have not yet received any reappraisal, using the heuristic strategy selection (negative + intense -> distancing, negative only -> reinterpretation, intense only -> temporal_distancing, otherwise -> benefit_finding)
- Optional LLM enhancement via Helpers::LlmEnhancer — `generate_reappraisal(event_content:, initial_appraisal:, strategy:, valence:, intensity:)` generates a strategy-aware, psychologically-grounded 1-2 sentence reappraisal for emotional events

## [0.1.0] - 2026-03-13

### Added
- Initial release
