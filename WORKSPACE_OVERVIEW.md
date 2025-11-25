# Blabbin Multi-Service Workspace Guide

This document explains how the four codebases in this workspace work together to power the Blabbin experience. Use it as a primer for onboarding, architectural reviews, and coordinating future refactors.

## Platform Snapshot
- **Frontend**: Flutter app in `Blabinn-Frontend` targeting mobile, web, and desktop.
- **Core API**: Node.js/Express backend in `blabin-backend` with Socket.IO for realtime features.
- **Chatbot**: FastAPI microservice in `chatify_chatbot` that orchestrates OpenAI, Firebase, and Redis session state.
- **Matchmaking monitor**: Redis-oriented queue/notification stack in `blabin-redis` (Node.js service + Python fallback scripts).
- **Shared services**: Firebase (auth, Firestore, storage), Render for hosting, Upstash Redis, OpenAI APIs, optional Cloudinary/Agora integrations.

## High-Level Architecture

```
Flutter Client (Blabinn-Frontend)
    │ REST / WebSocket
    ▼
Blabbin Backend (Express + Socket.IO)
    │ 1. real-time chat, matchmaking APIs
    │ 2. emits Redis monitoring requests
    │ 3. forwards AI timeout events
    ▼
Redis Monitoring Service (blabin-redis)
    │ monitors queue → notifies backend
    ▼
AI Orchestrator (within blabin-backend)
    │ calls
    ▼
Chatify Chatbot Microservice (FastAPI)
    │ OpenAI / Firebase / Redis session state
    ▼
OpenAI + Firebase (templates, transcripts)
```

### Random connection & AI fallback flow
1. **User initiates matching** from the Flutter app (`lib/screens/connect` and `lib/services/realtime_chat_service.dart`), sending REST+Socket.IO requests to `blabin-backend`.
2. Backend queues the user via `redisFallbackService` and, when allowed, through the `blabin-redis` HTTP API.
3. `blabin-redis` (or the in-memory fallback in `redisFallbackService.js`) tracks a 10-second timeout. When triggered, it POSTs `/api/v1/ai-fallback/timeout-notification` on the backend or emits a local `process` event.
4. `src/services/aiOrchestratorService.js` in the backend creates an AI session by calling the chatbot microservice’s `/api/v1/chatbot/session`.
5. The backend notifies the user’s Socket.IO room (`user:{id}`) with events such as `ai_chatbot_session_created` and `random_chat_event`.
6. Subsequent messages in rooms prefixed with `ai_` are proxied back to `chatify_chatbot`, which streams OpenAI responses to the frontend via Socket.IO.

### Data & identity backbone
- **Firebase**: Single identity provider; both backend and chatbot load service accounts from environment or bundled JSON (`firebaseServiceAccountKey.json`). Firestore stores profiles, chat logs, and personality templates.
- **Redis/Upstash**: Fast session + queue state, with optional “Redis-free” fallbacks when rate limits trigger.
- **OpenAI**: `chatify_chatbot` encapsulates prompt construction, enthusiasm controls, and demo-mode fallbacks when the API key is missing.

## Deployment & Operations
- **Render** hosts every service. Each repo includes a `render.yaml` describing the deployment type, build/start commands, and critical environment variables.
  - `chatify_chatbot/render.yaml` binds to `PORT=8000`, wraps `uvicorn` via `render_start_fixed.py`, and hardcodes an Upstash `REDIS_URL`.
  - `blabin-backend/render.yaml` runs `npm start`, configures CORS origins, and wires in `CHATBOT_SERVICE_URL` + `REDIS_SERVICE_URL`.
  - `blabin-redis/render.yaml` runs `node start-redis-free.js` in `REDIS_FREE_MODE`, pointing `BACKEND_URL` to the Render backend.
- **Keep-alive mechanics**: `chatify_chatbot/app/main.py` exposes `/ws/keepalive` to prevent Render idling. Background schedulers (APScheduer jobs for session cleanup) start on FastAPI startup.
- **Diagnostics**: Every service exposes `/health`. The backend and Redis services emit extensive console logs for deployment debugging (port selection, incoming requests, socket upgrades, Redis status).

## Service Deep Dives

### `chatify_chatbot` (FastAPI microservice)
- **Purpose**: Supplies AI chat fallback, personality templates, analytics, and API endpoints for the orchestrator and potential first-party clients.
- **Entrypoint**: `app/main.py` builds the FastAPI app, mounts routers from `app/api/v1/`, starts Socket.IO (`socket_service`), schedules cleanup jobs, and wraps everything in an ASGI app consumable by `uvicorn`.
- **Key routers**: `app/api/v1/endpoints/` includes REST handlers for chatbot sessions (`chatbot.py`), fallback control (`chatbot_fallback.py`), analytics, auth, profiles, and a `microservice` adapter exposing health/metrics endpoints.
- **Services**:
  - `session_service.py` maintains in-memory session state.
  - `openai_service.py` wraps OpenAI or provides demo responses.
  - `microservice_adapter.py` packages session create/send/end flows with retry, metrics, and structured responses for backend consumption.
  - `redis_service.py` synchronizes active sessions to Redis when available.
  - `socket_service.py` defines socket events (`join_chat`, `send_message`, `random_connection` events, etc.).
- **Configuration**: `app/core/config.py` loads `.env`, normalizes CORS lists, and exposes `settings.get_host/get_port` for safe Windows/Render binding.
- **Tests & utilities**: `tests/` hosts HTTPX-driven API tests; scripts such as `start_render.py`, `render_start_no_redis.py`, and `render_start_fixed.py` normalize Render port behaviour.
- **Docs**: `CHAT_FLOW.md`, `ARCHITECTURE_FLOW.md`, and multiple guides detail session logic, Firebase templates, and deployment steps.

### `blabin-backend` (Express + Socket.IO)
- **Purpose**: Core API + realtime gateway for user auth, profiles, chat, billing, analytics, AI fallback orchestration, and admin tooling.
- **Entrypoint**: `index.js` configures CORS, JSON parsing, static file serving, logs every request, mounts `src/api/`, attaches Socket.IO via `setupSocket`, initializes Firebase, and listens for `process` events from Redis fallback.
- **Sockets**: `src/socket/index.js` registers event handlers for `join`, `message`, `random chat` lifecycles, AI chatbot forwarding (`ai_` chat IDs), typing indicators, and connection debug logs. It broadcasts AI responses received from `aiOrchestratorService`.
- **API surface**: `src/api/` aggregates routers for auth, profiles, chat, connections, reports, premium, billing, analytics, verification, matching, and AI-specific endpoints accessible under `/api`.
- **Business services**:
  - `src/services/aiOrchestratorService.js` handles timeout notifications, session creation, message relay, and cleanup against the chatbot microservice.
  - `src/services/redisFallbackService.js` offers an in-memory monitoring mode and, when available, delegates to the Redis HTTP API.
  - Other subdirectories (`services/chat`, `services/connection`, `services/profile`, etc.) isolate feature domains.
- **Config & env**: `src/config/index.js` reads `.env`, sets dynamic CORS (including Render URLs), and normalizes Firebase private keys. Render injects `CHATBOT_SERVICE_URL`, `REDIS_SERVICE_URL`, etc.
- **Scripts & tests**: `scripts/` contains utility runners (Firebase index creation, cleanup jobs). `test-*.js` files provide targeted integration checks (email, billing, pagination, sockets).

### `blabin-redis` (Redis monitoring + queue)
- **Purpose**: Manages matchmaking queues, Redis persistence, timeout notifications, and auxiliary job processing.
- **Runtime**: Primarily Node.js/Express (`src/index.js`, `src/app.js`), augmented by Python services such as `redis_notification_service.py` and `start_redis_service.py` for Render-friendly deployments.
- **Core modules**:
  - `services/redis` handles Redis connection pooling and Upstash compatibility.
  - `services/queue` & `services/scheduler` manage job queues and (currently disabled) periodic matching.
  - `services/queue/SimplifiedUserMatchingService` implements interest-based matching heuristics with guardrails to avoid rate limits.
- **API**: Health endpoints, queue stats, and management routes are exposed via Express; the Python FastAPI service mirrors key routes (`/redis/set-matching-state`, `/redis/stats`, `/redis/health`).
- **Timeout workflow**: `redis_notification_service.py` runs an async loop that tracks monitoring state locally, rate-limits Redis operations, and posts timeout notifications to the backend. It can operate in a “Redis-free” mode to survive rate limiting.
- **Deployment**: Render launches `start-redis-free.js` with `REDIS_FREE_MODE=true`, instructing the service to avoid heavy Redis traffic.

### `Blabinn-Frontend` (Flutter client)
- **Purpose**: Multi-platform client implementing onboarding, matchmaking, chat UI, profile management, billing, ads, and analytics.
- **Structure** (`lib/`):
  - `core/` holds configuration (`config.dart`, `env_config.dart`, theme extensions, constants).
  - `models/`, `providers/`, and `state/` implement app state and domain models (chat, user, reports).
  - `screens/` contains feature modules (random chat, connect, onboarding, settings, media).
  - `services/` integrates with Firebase (`firebase_auth_service.dart`), REST (`api_service.dart`), sockets (`realtime_chat_service.dart`), ads, analytics, billing, and matching orchestrations.
  - `theme/`, `widgets/`, `ui/` deliver shared presentation components.
- **Networking**: `core/config.dart` builds REST & WebSocket base URLs from `EnvConfig`, which currently point to Render (`https://blabbin-backend-rsss.onrender.com`). Socket.IO clients emit and respond to the same events exposed in the backend.
- **Third-party hooks**: Placeholders for Google Translate, Cloudinary, Agora are wired through constants; enabling them requires populating the secrets in `EnvConfig`.
- **Tooling**: `setup_linting.sh/.bat` plus `analysis_options.yaml` enforce lint rules. `docs/` and multiple Markdown guides (ads, analytics, testing) augment dev workflows.

## Shared Contracts & Integrations
- **REST endpoints**:
  - Chatbot service: `/api/v1/chatbot/session`, `/api/v1/chatbot/session/{id}/message`, `/api/v1/chatbot/session/{id}` (DELETE), `/api/v1/ai-fallback/*` for orchestrator hooks.
  - Backend API root lists relevant base routes under `/api`.
  - Redis monitor: `/redis/set-matching-state`, `/redis/remove-matching-state`, `/redis/stats`.
- **Socket.IO events**:
  - Frontend ↔ backend: `join`, `message`, `message_sent`, `new_message`, `user_online/offline`, `typing`, `random_chat_event`.
  - AI fallback: `ai_chatbot_session_created`, `random_chat_session_ended`, AI broadcasts when `chatId` starts with `ai_`.
  - Chatbot Socket.IO supports `join_chat`, `send_message`, `start_random_connection`, `end_random_chat_session`.
- **Environment variables to align**:
  - Backend: `PORT`, `NODE_ENV`, `CORS_ORIGIN`, `CHATBOT_SERVICE_URL`, `REDIS_SERVICE_URL`, Firebase credentials.
  - Chatbot: `PORT`, `HOST`, `BACKEND_CORS_ORIGINS`, `OPENAI_API_KEY`, Firebase + Redis settings.
  - Redis: `PORT`, `HOST`, `BACKEND_URL`, `REDIS_FREE_MODE`, Upstash credentials if Redis mode is enabled.
  - Frontend: `EnvConfig` must match deployed URLs and feature toggles.

## Local Development & Testing
- **Backend**: `npm run dev` launches Express with nodemon; `.env.example` seeds environment variables. Per-feature test scripts exist under `tests/` and `scripts/`.
- **Chatbot**: `uvicorn app.main:app --reload` or `python start_simple.py` for local runs. HTTPX-based tests live in `tests/`. `.env.example` covers required OpenAI/Firebase keys.
- **Redis service**: `python start_redis_service.py` runs the FastAPI notifier; Node variant starts via `npm run dev`. `requirements.txt` enumerates Python dependencies.
- **Frontend**: `flutter run` from `Blabinn-Frontend` targeting desired platforms. `EnvConfig` toggles between local IPs and Render endpoints; `setup_linting.*` scripts configure static analysis.
- **End-to-end sanity**: Integration smoke tests such as `chatify_chatbot/test_chatbot_integration.py`, `blabin-backend/test-connection.js`, and `blabin-redis/test-connection.js` validate key workflows.

## Observability & Background Jobs
- **Logging**: Verbose console logs in backend and Redis highlight incoming requests, socket upgrades, timeout events, AI orchestration results, and Redis rate limiting.
- **Schedulers**:
  - Chatbot: APScheduler jobs for session and Redis cleanup every 5–15 minutes.
  - Redis: Queue processors and schedulers exist but are disabled in production to respect rate limits.
- **Health endpoints** allow Render and manual probes to verify readiness (`/health`, `/api/health`, `/redis/health`).

## Additional References
- Chat flow and architecture diagrams: `chatify_chatbot/CHAT_FLOW.md`, `ARCHITECTURE_FLOW.md`.
- Backend domain guides: `src/services/**/README.md` (chat, connection, profile services).
- Redis service setup: `blabin-redis/REDIS_SETUP.md`, `FRIENDS_MATCHING_IMPLEMENTATION.md`.
- Frontend documentation: numerous Markdown files under `Blabinn-Frontend/docs/` covering linting, ads, analytics, testing, and background imagery.

## Notes for Architecture Review
- Redis usage is deliberately throttled; evaluate whether upgrading plan or consolidating the Python and Node services would simplify the architecture.
- The AI orchestrator depends on HTTP retries against the chatbot; consider circuit breakers or message queues for resilience.
- Firebase credentials are currently bundled in repo; ensure secrets are rotated and moved to environment storage before production.
- Frontend `EnvConfig` defaults to production URLs—create flavours or build-time configs if you need local/offline development.
- Render deployments rely on keep-alive scripts. If migrating hosting, port binding and process management scripts (`render_start_fixed.py`, `start_render.py`, etc.) may need replacement.


