# Greenlight — Production-Grade Go Backend API

![Go Version](https://img.shields.io/badge/Go-1.26%2B-00ADD8?style=for-the-badge&logo=go&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-18-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![httprouter](https://img.shields.io/badge/httprouter-v1.3.0-00599C?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)

**Greenlight** is a production-grade, highly concurrent RESTful JSON API for managing movie data, user accounts, and token-based activation/authentication workflows. Built from the ground up using **Idiomatic Go**, clean architectural boundaries, and a standard-library-first approach, Greenlight demonstrates production backend patterns including rate limiting, optimistic concurrency control, role-based access control (RBAC), CORS middleware, graceful shutdown, asynchronous email dispatch, and expvar metrics.

> **Project Origin:** Developed while mastering backend engineering principles from *Let's Go Further* by Alex Edwards. Greenlight serves as a core architectural foundation for production Go services.

---

## 🏛 Architecture & Vision

Greenlight eschews heavy all-in-one frameworks in favor of composable Go standard library packages and explicit dependency injection. The architecture enforces separation of concerns across distinct layers:

* **HTTP Layer (`cmd/api`)**: Routing (`httprouter`), request decoding/validation, JSON envelope serialization, error handling, middleware pipeline, and graceful server lifecycle management.
* **Domain & Data Layer (`internal/data`)**: Encapsulates models, PostgreSQL queries, check constraints, GIN indexes, type extensions (custom JSON serialization), and permission checks.
* **Infrastructure Services (`internal/mailer`, `internal/validator`, `internal/vcs`)**: Dedicated, decoupled components for SMTP email delivery, input validation, and VCS version extraction.

---

## ⚡ Key Technical Features & Deep Dive

### 1. HTTP Middleware & Custom Rate Limiting
* **Token Bucket Rate Limiting**: Built using `golang.org/x/time/rate`, assigning limiters dynamically per client IP.
* **Real IP Extraction & Memory Cleanup**: Uses `github.com/tomasen/realip` behind reverse proxies. Runs a background goroutine to clean inactive client IP entries every minute, preventing memory leaks.
* **Panic Recovery**: Catches panics gracefully, setting `Connection: close` and returning standardized 500 JSON error responses.
* **Configurable CORS**: Middleware supporting preflight `OPTIONS` requests, `Vary: Origin`, and a configurable trusted origin whitelist via CLI flags.

### 2. Authentication, Activation & RBAC Permissions
* **Password Hashing**: Securely hashes passwords using `bcrypt` (cost 12).
* **Cryptographic Tokens**: Generates 26-character high-entropy tokens (`crypto/rand`) stored as 256-bit SHA-256 hashes in PostgreSQL for activation and authentication scopes.
* **Bearer Authentication**: Stateful token validation via the `Authorization: Bearer <TOKEN>` header, injecting user context into requests.
* **Role-Based Permissions**: Granular permissions table (`movies:read`, `movies:write`). New users automatically receive `movies:read` upon signup; restricted mutations require `movies:write`.

### 3. Database Layer & PostgreSQL Optimization
* **Optimistic Concurrency Control**: Implements record versioning (`version = version + 1`). Edit conflicts (`sql.ErrNoRows`) return HTTP `409 Conflict`.
* **Full-Text Search & Filtering**: Leverages PostgreSQL GIN indexes for title searches (`to_tsvector`, `plainto_tsquery`) and array filtering (`genres @> $2`).
* **Connection Pool Tuning**: Dynamically configures `max-open-conns`, `max-idle-conns`, and `max-idle-time`.

### 4. Metrics & Automated Versioning
* **Expvar Metrics (`/debug/vars`)**: Custom metrics middleware capturing total requests received, responses sent, processing time, and status code counts alongside runtime memory, goroutine counts, and database pool statistics.
* **Dynamic VCS Versioning**: Uses `runtime/debug.ReadBuildInfo()` to report the current git commit and build version via the `-version` flag and `/debug/vars`.

### 5. Concurrency Control & Graceful Shutdown
* **Signal Interception**: Catches `SIGINT` and `SIGTERM` to initiate coordinated server teardown.
* **Context Timeout & WaitGroup**: Integrates `http.Server.Shutdown()` with a 30-second context timeout and tracks background goroutines using `sync.WaitGroup` to guarantee transactional jobs (e.g. email delivery) complete safely.

---

## 🚀 API Reference

All requests and responses use JSON formatting with structured envelopes (`{"movie": ...}`, `{"error": ...}`).

| Method | Endpoint | Auth / Permission | Description |
|---|---|---|---|
| `GET` | `/v1/healthcheck` | Public | Returns system operational status and environment info |
| `POST` | `/v1/users` | Public | Registers a user & triggers an asynchronous activation email |
| `PUT` | `/v1/users/activated` | Public | Activates an account using the emailed 26-character token |
| `POST` | `/v1/tokens/authentication` | Public | Exchanges credentials (email & password) for a Bearer auth token |
| `GET` | `/v1/movies` | `movies:read` | Paginated movie search, genre filtering, and dynamic sorting |
| `GET` | `/v1/movies/:id` | `movies:read` | Fetches details for a specific movie |
| `POST` | `/v1/movies` | `movies:write` | Creates a new movie entry |
| `PATCH` | `/v1/movies/:id` | `movies:write` | Partial update with optimistic concurrency control |
| `DELETE` | `/v1/movies/:id` | `movies:write` | Deletes a movie entry by ID |
| `GET` | `/debug/vars` | Public | Returns expvar runtime metrics, DB pool stats, & version |

---

## 📁 Project Structure

```txt
greenlight
├── cmd
│   └── api
│       ├── context.go         # Request context helpers (user injection)
│       ├── errors.go          # Standardized JSON error response builders
│       ├── healthcheck.go     # Healthcheck endpoint handler
│       ├── helpers.go         # JSON read/write helpers & background goroutines
│       ├── main.go            # Application entrypoint & configuration setup
│       ├── middleware.go      # Rate limiting, panic recovery, CORS, auth & metrics
│       ├── movies.go          # Movie resource handlers (CRUD + filtering)
│       ├── routes.go          # Route mapping & middleware pipeline
│       ├── server.go          # Graceful HTTP server startup and shutdown logic
│       ├── token.go           # Authentication token generation handler
│       └── users.go           # User registration & account activation handlers
├── internal
│   ├── data
│   │   ├── filters.go         # Pagination, sorting, and safelist validation
│   │   ├── models.go          # Master models container & error definitions
│   │   ├── movies.go          # PostgreSQL data access layer for movies
│   │   ├── permissions.go     # User permissions model (RBAC)
│   │   ├── runtime.go         # Custom JSON duration type ("107 mins")
│   │   ├── tokens.go          # Token generation, hashing, and database storage
│   │   └── users.go           # User model, bcrypt hashing, and database queries
│   ├── mailer
│   │   ├── mailer.go          # SMTP client execution via go-mail
│   │   └── templates/         # Embedded text/HTML email templates (go:embed)
│   ├── validator
│   │   └── validator.go       # Input validation engine
│   └── vcs
│       └── vcs.go             # Build info extraction via runtime/debug
├── migrations                 # Sequential SQL migration files
├── compose.yml                # Compose setup for PostgreSQL 18 & Mailpit
├── justfile                   # Task runner commands (just)
├── mise.toml                  # Task runner & environment config (mise)
└── go.mod                     # Go module & dependencies
```

---

## 🛠 Getting Started & Local Development

### Prerequisites

* **Go**: 1.26 or higher
* **Container Engine**: [Docker](https://www.docker.com/) or [Podman](https://podman.io/)
* **Database Migrations**: [golang-migrate](https://github.com/golang-migrate/migrate)
* **Task Runner (Optional)**: [just](https://github.com/casey/just) or [mise](https://mise.jdx.dev/)

### 1. Environment & Database Setup

Clone the repository and configure your environment variables:

```bash
git clone https://codeberg.org/mazen-dev/greenlight.git
cd greenlight

# Export required database credentials
export DB_NAME="greenlight"
export DB_PASSWORD="pa55word"
export DSN="postgres://${DB_NAME}:${DB_PASSWORD}@localhost:5432/${DB_NAME}?sslmode=disable"
```

Start the PostgreSQL 18 and Mailpit containers:

```bash
# Using just
just compose-up

# Using mise
mise run compose:up

# Or directly with Docker / Podman
docker compose up -d
```

### 2. Run Database Migrations

Apply sequential database migrations:

```bash
# Using just
just db-migrations-up

# Using mise
mise run db:migrate

# Or using migrate CLI directly
migrate -path=./migrations -database=$DSN up
```

### 3. Run the Application

```bash
# Using just
just run-api

# Using mise
mise run run:api

# Or using standard Go CLI
go run ./cmd/api -db-dsn=$DSN
```

Available CLI configuration flags:
- `-port` (default `4000`)
- `-env` (default `development`)
- `-db-dsn` (default from `$DSN`)
- `-db-max-open-conns` (default `25`), `-db-max-idle-conns` (default `25`), `-db-max-idle-time` (default `15m`)
- `-limiter-rps` (default `2`), `-limiter-burst` (default `4`), `-limiter-enabled` (default `true`)
- `-smtp-host`, `-smtp-port`, `-smtp-username`, `-smtp-password`, `-smtp-sender`
- `-cors-trusted-origins` (space-separated trusted origins list)
- `-version` (prints application version and exits)

### 4. Code Quality & Auditing

```bash
# Tidy, verify, vendor dependencies and format code
just tidy
# Run staticcheck, vet, and race-detector tests
just audit
```

---

## 🧪 Example Usage & Quickstart

### 1. Healthcheck Endpoint (Public)

```bash
curl -i http://localhost:4000/v1/healthcheck
```

### 2. Register a New User

```bash
curl -i -X POST http://localhost:4000/v1/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Jane Doe",
    "email": "jane@example.com",
    "password": "pa55wordString"
  }'
```

### 3. Activate the User Account

Using the 26-character activation token received in Mailpit (`http://localhost:8025`):

```bash
curl -i -X PUT http://localhost:4000/v1/users/activated \
  -H "Content-Type: application/json" \
  -d '{
    "token": "<ACTIVATION_TOKEN_FROM_EMAIL>"
  }'
```
*Activating the account automatically grants the `movies:read` permission.*

### 4. Generate an Authentication Token

```bash
curl -i -X POST http://localhost:4000/v1/tokens/authentication \
  -H "Content-Type: application/json" \
  -d '{
    "email": "jane@example.com",
    "password": "pa55wordString"
  }'
```

Save the `token` value from the JSON response:
```bash
export TOKEN="<YOUR_AUTHENTICATION_TOKEN>"
```

### 5. Query Movies with Search, Filters & Pagination

```bash
curl -i "http://localhost:4000/v1/movies?title=moana&genres=animation&page=1&page_size=10&sort=-year" \
  -H "Authorization: Bearer $TOKEN"
```

### 6. Grant `movies:write` Permission & Create a Movie

To create or modify movies, the user requires the `movies:write` permission. Grant it via `psql`:

```bash
just db-psql
# Inside psql:
# INSERT INTO users_permissions
#   SELECT id, (SELECT id FROM permissions WHERE code = 'movies:write')
#   FROM users WHERE email = 'jane@example.com';
```

Now create a new movie:

```bash
curl -i -X POST http://localhost:4000/v1/movies \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Moana",
    "year": 2016,
    "runtime": "107 mins",
    "genres": ["animation", "adventure"]
  }'
```

### 7. Inspect Runtime Metrics (`/debug/vars`)

```bash
curl -i http://localhost:4000/debug/vars
```

---

## 🗺 Future Roadmap

- [ ] **Stateless Authentication**: Add optional JWT token support alongside stateful database tokens.
- [ ] **Distributed Tracing**: OpenTelemetry instrumentation for distributed microservices.
- [ ] **Prometheus Exporter**: Expose a standard `/metrics` endpoint for Prometheus scraping.
- [ ] **Frontend Application**: Visual dashboard for browsing and managing movies.

---

## 📜 License

Distributed under the MIT License. See `LICENSE` for more information.
