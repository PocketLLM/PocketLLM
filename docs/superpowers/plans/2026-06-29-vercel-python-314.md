# Vercel Python 3.14 Deployment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the PocketLLM FastAPI backend deploy reliably to Vercel using Python 3.14.

**Architecture:** Repository-owned Vercel configuration overrides the erroneous dashboard build command and selects the FastAPI preset. A small standard-library regression test enforces the runtime, entrypoint, and build-command contract.

**Tech Stack:** Python 3.14, FastAPI, Vercel Functions, `unittest`, Flutter

---

### Task 1: Add a failing deployment configuration test

**Files:**
- Create: `pocketllm-backend/tests/test_vercel_deployment_config.py`

- [ ] Write a `unittest` test that requires Python 3.14 in `.python-version` and `pyproject.toml`, requires `tool.vercel.entrypoint = "main:app"`, and requires `vercel.json` to select FastAPI with a null build command.
- [ ] Run `python -m unittest tests.test_vercel_deployment_config -v` and confirm it fails because the repository still selects Python 3.12 and has no `vercel.json`.

### Task 2: Implement repository-owned Vercel configuration

**Files:**
- Modify: `pocketllm-backend/.python-version`
- Modify: `pocketllm-backend/pyproject.toml`
- Create: `pocketllm-backend/vercel.json`

- [ ] Set both Python declarations to the 3.14 minor line.
- [ ] Declare every `requirements.txt` package in `project.dependencies` so the Vercel function bundle contains all runtime imports.
- [ ] Configure Vercel with `framework: "fastapi"` and `buildCommand: null` while retaining `main:app` as the entrypoint.
- [ ] Re-run `python -m unittest tests.test_vercel_deployment_config -v` and confirm it passes.

### Task 3: Clean ignored generated files

**Files:**
- Modify: `.gitignore`
- Modify: `pocketllm-backend/.gitignore`
- Delete: `pocketllm-website/.npm/_update-notifier-last-checked`

- [ ] Ignore `.npm`, `node_modules`, Python tooling caches, virtual environments, and distribution outputs.
- [ ] Confirm `git check-ignore` reports the expected rules and `git ls-files` reports no tracked cache artifacts.

### Task 4: Document deployment behavior

**Files:**
- Modify: `pocketllm-backend/README.md`

- [ ] Document Python 3.14, Vercel zero-configuration FastAPI deployment, and why `uvicorn --reload` is local-development-only.

### Task 5: Verify and deploy

**Files:** None

- [ ] Run the backend unit tests inside the project virtual environment.
- [ ] Run `flutter analyze`, `flutter test`, and `flutter build apk --debug`.
- [ ] Deploy the backend through the connected Vercel project.
- [ ] Inspect build/runtime logs and request `/health`; require HTTP 200 before reporting success.
