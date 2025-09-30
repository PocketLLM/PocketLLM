# AI Engineering Notes

This backend is intended to power PocketLLM's conversational features. When extending the system keep the following in mind:

1. **Supabase-first architecture** – Use Supabase auth tokens for all protected endpoints. Database writes should go through the
   async `Database` helper which enforces pooled connections and consistent transactions.
2. **Service layer responsibility** – Any business logic belongs in `app/services`. Routers should remain thin wrappers around the
   services and handle only request/response conversion.
3. **Schema-driven development** – Define request/response shapes in `app/schemas`. The same models are used for validation,
   documentation, and serialization.
4. **Background jobs** – Use `JobsService` to enqueue work. The current implementation stores jobs in Postgres and simulates
   processing using `asyncio`. Replace `_process_image_job` with real integrations when ready.
5. **Logging + tracing** – The middleware stack sets `request_id` headers and structured logging. Include `request.state.request_id`
   in any downstream logs for easier debugging.
6. **Testing** – Add Pytest cases under `tests/` whenever endpoints or services are extended. Prefer dependency injection (e.g.
   passing mock database instances) for deterministic tests.

For onboarding new features, update `API_DOCUMENTATION.md` and `api_structure.json` so the contract stays synchronised with the
implementation.
