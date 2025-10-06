# Language Test App – Agent Guide

This repository now contains the **Language Test App**, a Next.js (App Router) project written in TypeScript.

## Required Workflow

1. **Install dependencies before working**
   ```bash
   npm install
   ```
2. **Quality gates before submitting a PR**
   ```bash
   npm run lint
   npm run test
   ```
3. **Code style expectations**
   - Follow idiomatic React + TypeScript patterns.
   - Prefer functional components and hooks.
   - Keep modules focused; extract shared logic into `src/lib`.
   - Maintain strong typing—avoid `any`.
   - Document non-trivial logic with inline comments when needed.
4. **Testing guidelines**
   - Unit tests live under `src/__tests__` and should cover new logic in `src/lib` or hooks.
   - Use [Vitest](https://vitest.dev) and Testing Library utilities for component behavior.
5. **Documentation**
   - Update `README.md` and `docs/` when altering workflows or architecture.
   - Record significant architectural decisions in `docs/architecture.md`.

Follow these steps for every change to keep the project production-ready.
