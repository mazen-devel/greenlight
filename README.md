# Greenlight — Production-Grade Go Backend API

[![Go Version](https://img.shields.io/badge/Go-1.26%2B-00ADD8?style=for-the-badge&logo=go&logoColor=white)](https://go.dev/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-18-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Router](https://img.shields.io/badge/httprouter-v1.3.0-00599C?style=for-the-badge)](https://github.com/julienschmidt/httprouter)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)

**Greenlight** is a production-grade, highly concurrent RESTful JSON API for managing movie data, user accounts, and token-based activation workflows. Built from the ground up using **Idiomatic Go**, clean architectural boundaries, and a zero-framework approach, Greenlight demonstrates standard-library-first backend patterns including rate limiting, optimistic concurrency control, graceful shutdown, and asynchronous background tasks.

> **Project Origin:** Developed while mastering backend engineering principles from *Let's Go Further* by Alex Edwards. Greenlight serves as a core architectural foundation for production Go services and powers portfolio backend infrastructure.

---

## 🏛 Architecture & Vision

Greenlight eschews heavy all-in-one frameworks in favor of composable Go standard library packages and explicit dependency injection. The architecture enforces separation of concerns across distinct layers:

* **HTTP Layer (`cmd/api`)**: Responsible for routing, parameter parsing, dynamic JSON envelopes, response generation, middleware, and server lifecycle management.
* **Domain & Data Layer (`internal/data`)**: Encapsulates data models, validation rules, type extensions (e.g. custom JSON serialization), and SQL queries utilizing PostgreSQL features.
* **Infrastructure Services (`internal/mailer`, `internal/validator`)**: Dedicated, decoupled components for email delivery and input validation.

---

## ⚡ Key Technical Features & Deep Dive

### 1. HTTP Middleware & Custom Rate Limiting
* **Token Bucket Algorithm**: Built using `golang.org/x/time/rate`, assigning individual limiters dynamically per IP.
* **IP Parsing & Memory Cleanup**: Utilizes `github.com/tomasen/realip` to extract authentic client IPs behind proxies. Includes a background goroutine that runs periodic sweeps to clean up inactive IP map entries, preventing memory leaks over time.
* **Panic Recovery**: Catches panics gracefully, setting a `Connection: close` header and returning standardized 500 JSON error responses.

### 2. Concurrency Control & Graceful Shutdown
* **Signal Interception**: Intercepts `SIGINT` and `SIGTERM` OS signals to initiate server teardown.
* **Context Timeout & WaitGroup**: Integrates `http.Server.Shutdown()` with a 30-second context timeout and tracks background goroutines using `sync.WaitGroup`, ensuring pending tasks (such as welcome email sends) complete without data loss during deployment or shutdown.

### 3. Database Layer & PostgreSQL Optimization
* **Optimistic Concurrency Control**: Implements versioning (`version = version + 1`) on table updates. Detects edit conflicts (`sql.ErrNoRows`) and returns HTTP `409 Conflict` responses to prevent race conditions.
* **Advanced Querying**: Leverages PostgreSQL GIN indexes for Full-Text Search (`to_tsvector`, `plainto_tsquery`) and array filtering (`genres @> $2`).
* **Database Connection Pool Tuning**: Dynamically configures `MaxOpenConns`, `MaxIdleConns`, and `ConnMaxIdleTime` via runtime flags.

### 4. Authentication, Activation & Security
* **Password Hashing**: Securely hashes user passwords using `bcrypt` with a cost factor of 12.
* **Cryptographic Token Generation**: Generates high-entropy random activation tokens using `crypto/rand` and stores 256-bit SHA-256 hashes in PostgreSQL.
* **Custom Type Serialization**: Implements custom `MarshalJSON` and `UnmarshalJSON` interfaces for the `Runtime` type to seamlessly parse and render durations formatted as `"107 mins"`.

### 5. Asynchronous Mailer System
* **Embedded Templates**: Uses Go `embed.FS` (`//go:embed`) to ship HTML/text template files directly inside the compiled binary.
* **Non-blocking Email Dispatch**: Offloads transactional emails (e.g., user welcome & activation messages) to decoupled background goroutines using safe execution wrappers.

---

## 🚀 API Reference

All requests and responses use JSON formatting with structured outer envelopes (`{"movie": ...}`, `{"error": ...}`).

| Method | Endpoint | Auth / Token | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/v1/healthcheck` | Public | Returns system operational status and environment info |
| `GET` | `/v1/movies` | Public | Paginated list of movies with title search, genre filters, & sorting |
| `POST` | `/v1/movies` | Public | Creates a new movie entry |
| `GET` | `/v1/movies/:id` | Public | Fetches detailed information for a specific movie |
| `PATCH` | `/v1/movies/:id` | Public | Partial update of movie fields with optimistic locking |
| `DELETE` | `/v1/movies/:id` | Public | Deletes a movie entry by ID |
| `POST` | `/v1/users` | Public | Registers a new account & sends asynchronous activation token |
| `PUT` | `/v1/users/activated` | Public | Activates user account using a valid activation token |
| `POST` | `/v1/tokens/authentication` | Public | Generates a authentication token given valid user credentials (email & password) |

---

## 📁 Project Structure
``` txt
greenlight
├── cmd
│   └── api
│       ├── errors.go         # Standardized JSON error response builders
│       ├── healthcheck.go    # Healthcheck endpoint handler
│       ├── helpers.go        # JSON read/write helpers, query string parsing & bg goroutines
│       ├── main.go           # Application entrypoint & configuration setup
│       ├── middleware.go     # Rate limiting & panic recovery middleware
│       ├── movies.go         # Movie resource handlers (CRUD + filtering)
│       ├── routes.go         # httprouter mapping & middleware chain assembly
│       ├── server.go         # Graceful HTTP server startup and shutdown logic
│       └── users.go          # User registration & account activation handlers
├── internal
│   ├── data
│   │   ├── filters.go        # Pagination, dynamic sorting, and safelist validation
│   │   ├── models.go         # Master data models container & error definitions
│   │   ├── movies.go         # PostgreSQL data access layer for movies
│   │   ├── runtime.go        # Custom JSON marshaling for movie runtimes ("X mins")
│   │   ├── tokens.go         # Secure activation/auth token generation & storage
│   │   └── users.go          # User model, bcrypt hashing, and database queries
│   ├── mailer
│   │   ├── mailer.go         # SMTP client execution via go-mail
│   │   └── templates/        # Embedded text/HTML email templates
│   └── validator
│       └── validator.go      # Concurrent-safe input validation rules engine
├── migrations                # Sequential SQL migration files for PostgreSQL
├── compose.yml               # Docker/Podman compose setup for Postgres & Mailpit
├── mise.toml                 # Task runner & tool version configurations
├── go.mod                    # Go dependency specifications
└── README.md                 # Project documentation
```
---

## 🛠 Getting Started & Local Development

### Prerequisites

* **Go**: 1.26 or higher
* **Container Engine**: [Docker](https://www.docker.com/) or [Podman](https://podman.io/)
* **Migrate CLI**: [golang-migrate](https://github.com/golang-migrate/migrate) (Optional if using `mise`)
* **Mise** (Optional task runner): [mise-en-place](https://mise.jdx.dev/)

### 1. Environment & Database Setup

Clone the repository and start the development containers (PostgreSQL 18 & Mailpit):
``` bash
git clone https://codeberg.org/mazen-dev/greenlight.git
cd greenlight

# Export required database credentials for container startup
export DB_NAME="greenlight"
export DB_PASSWORD="<the password>"

# Export standard database DSN used by mise and golang-migrate
export GREENLIGHT_DB_DSN="postgres://${DB_NAME}:${DB_PASSWORD}@localhost:5432/greenlight?sslmode=disable"
```

# Start PostgreSQL and Mailpit services via mise or docker-compose
``` bash
mise run up
# OR: podman-compose up -d / docker compose up -d
``` 

### 2. Run Database Migrations

Apply database migrations to set up the schema, check constraints, and GIN indexes:

``` bash
migrate -path=./migrations -database=$GREENLIGHT_DB_DSN up
```

### 3. Run the Application

Start the API server:
``` bash
# Using mise shortcut
mise run r

# OR using standard Go CLI
go run ./cmd/api -db-dsn=$GREENLIGHT_DB_DSN
```

---

## 🧪 Example Usage & Quickstart

### 1. Healthcheck Endpoint
``` bash
curl -i http://localhost:4000/v1/healthcheck
```

### 2. Create a New Movie
``` bash
curl -i -X POST http://localhost:4000/v1/movies \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Moana",
    "year": 2016,
    "runtime": "107 mins",
    "genres": ["animation", "adventure"]
  }'
``` 

### 3. Query Movies with Search, Filters & Pagination
``` bash
curl -i "http://localhost:4000/v1/movies?title=moana&genres=animation&page=1&page_size=10&sort=-year"
```

### 4. Register a User Account
``` bash
curl -i -X POST http://localhost:4000/v1/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Jane Doe",
    "email": "jane@example.com",
    "password": "pa55wordString"
  }'
```
> **Note:** Open Mailpit at `http://localhost:8025` to inspect the generated welcome email and extract the 26-character activation token.

### 5. Activate User Account
``` bash
curl -i -X PUT http://localhost:4000/v1/users/activated \
  -H "Content-Type: application/json" \
  -d '{
    "token": "YOUR_26_CHARACTER_TOKEN"
  }'
```

---

## 🗺 Future Roadmap

- [ ] **Stateful / Stateless Authentication**: Implement JWT tokens and Bearer authentication middleware.
- [ ] **Permission-Based Authorization**: Fine-grained role/permission checks on restricted endpoints (`movies:read`, `movies:write`).
- [ ] **Metrics & Tracing**: Integrate Prometheus metrics and OpenTelemetry tracing.
- [ ] **Frontend Application**: Build a modern web application interface for visual movie management.

---

## 📜 License

Distributed under the MIT License. See `LICENSE` for more information.
