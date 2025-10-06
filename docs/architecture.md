# Architecture Overview

The Language Test App is a single-page experience built with Next.js App Router. The core flow is:

1. **Configure a session** – educators select the target CEFR level, number of questions per skill, and whether to enable timing.
2. **Deliver adaptive items** – the `useTestSession` hook serves questions drawn from a curated bank, tracking score and progress.
3. **Review results** – an instant summary highlights section strengths, weaknesses, and recommendations.

## Key Modules

- `src/data/questionBank.ts` – CEFR-aligned practice items tagged by skill and difficulty.
- `src/lib/evaluation.ts` – Pure scoring and recommendation utilities.
- `src/hooks/useTestSession.ts` – Encapsulates session lifecycle, timers, and response collection.
- `src/components/*` – Presentation components for configuration, active sessions, and reporting.

## State Management

Session state is entirely client-side via React hooks. The `useTestSession` hook exposes:

- `status`: `idle | running | complete`
- `config`: Active configuration metadata
- `question`: Current question payload
- `progress`: Index-based progress helpers
- `responses`: Collected answers with timestamps
- `results`: Derived scoring summary once complete

This architecture keeps evaluation deterministic and easy to test.

## Styling

Global tokens live in `src/styles/globals.css` using CSS custom properties for light/dark modes. Components rely on these tokens and utility classes built with CSS modules.
