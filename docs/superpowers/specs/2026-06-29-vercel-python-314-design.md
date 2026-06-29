# Vercel Python 3.14 Deployment Design

## Goal

Deploy the FastAPI backend on Vercel with one consistent Python 3.14 runtime and prevent a development server from running during the build phase.

## Design

- Declare Python 3.14 in both `pocketllm-backend/.python-version` and `pocketllm-backend/pyproject.toml`.
- Add `pocketllm-backend/vercel.json` with the FastAPI framework preset and a null build command. This overrides the Vercel dashboard command `python -m uvicorn main:app --reload`, allowing Vercel to package `main:app` as a Function.
- Keep the existing `[tool.vercel]` entrypoint because `main.py` exports the application as `app`.
- Mirror `requirements.txt` in the PEP 621 `project.dependencies` list because Vercel installs from `pyproject.toml` when a project table is present.
- Validate the deployment files with a standard-library unit test so configuration regressions do not depend on Vercel access.
- Extend ignore rules to exclude local package-manager caches and remove the already tracked `.npm` cache marker.
- Document the supported runtime and the requirement that production deployments must not start Uvicorn during the build.

## Verification

Run the deployment configuration test, backend test suite, Flutter analysis/tests/debug APK build, then deploy through Vercel and verify `/health` returns HTTP 200.
