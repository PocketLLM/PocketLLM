# Frontend Cleanup Task List

This document enumerates the hardcoded or client-owned behaviors in the current Flutter
frontend and outlines the backend-first refactor work required to finish the migration.
Items are grouped by feature area and reference the relevant source files.

## 1. Authentication & Profile
- **`lib/services/pocket_llm_service.dart`, `lib/services/auth_state.dart`**
  - Replace local API key initialization and secure-storage token management with
    backend-issued credentials. Remove the fallback demo key bundled with the app.
  - Ensure all login, logout, and profile refresh flows call backend endpoints only;
    eliminate shared-preference flags such as `authSkipped` once server-driven sessions
    are enforced.
- **`lib/pages/auth/auth_page.dart`, `lib/pages/auth/auth_flow_screen.dart`**
  - Audit UI flows that bypass authentication ("Skip" path) and coordinate with backend
    requirements before keeping or removing the option.

## 2. Model Management
- **`lib/component/models.dart`, `lib/services/model_service.dart`, `lib/services/model_state.dart`**
  - Stop persisting models purely on device; move CRUD, health checks, and default model
    selection to backend APIs.
  - Align the local enums/metadata with backend contracts and consider generating models
    from shared schemas.
- **`lib/component/model_config_dialog.dart`, `lib/component/model_list_item.dart`, `lib/pages/model_settings_page.dart`**
  - Remove direct HTTP calls to provider APIs. Instead, let the backend broker provider
    imports and return sanitized configuration options.
- **`lib/component/ollama_model.dart`, `lib/pages/library_page.dart`, `lib/component/model_parameter_dialog.dart`**
  - Delete or fully rework the embedded Ollama catalog and Termux automation once server
    orchestrates model downloads. Device-level shell execution should be retired.

## 3. Chat & Conversation Storage
- **`lib/services/chat_service.dart`, `lib/component/chat_interface.dart`**
  - Route all chat completions through backend gateways; drop per-provider HTTP clients
    and inline API keys.
  - Replace Tavily direct calls (`lib/component/tavily_service.dart`) with backend search
    proxy endpoints.
- **`lib/services/chat_history_service.dart`, `lib/component/chat_history_manager.dart`, `lib/component/appbar/chat_history.dart`**
  - Migrate conversation persistence from shared preferences to backend storage so chat
    history syncs across devices.

## 4. Search Integrations
- **`lib/services/search_service.dart`, `lib/component/search_config_dialog.dart`,
  `lib/pages/search_settings_page.dart`**
  - Remove local credential storage and HTTP calls. Persist search provider settings on
    the backend and expose a unified search API to the client.

## 5. Device / Termux Utilities
- **`lib/services/termux_service.dart`, `lib/pages/config_page.dart`, `lib/pages/library_page.dart`**
  - Reassess whether on-device Termux automation remains in scope. If the backend manages
    model deployments, delete these classes and replace with server-triggered workflows.

## 6. Documentation & Content
- **`lib/component/appbar/docs.dart`, `lib/pages/docs_page.dart`**
  - Remove duplicated hardcoded markdown and fetch documentation links/content from the
    backend or a CMS.

## 7. General Cleanup
- Ensure every module that currently reads/writes `SharedPreferences` is evaluated. Any
  persisted state that should be portable (API keys, models, surveys, chat transcripts)
  must be migrated to backend storage with secure access control.
- After backend services cover these responsibilities, delete unused classes, constants,
  and UI affordances that were designed around device-only execution.

Completing these tasks will leave the Flutter codebase responsible for presentation and
lightweight orchestration while the backend owns state, credentials, and integrations.
