# Greenlight

A RESTful movie information API written in Go, using [httprouter](https://github.com/julienschmidt/httprouter) and PostgreSQL.

This project was built while working through *Let's Go Further* by Alex Edwards, then extended with additional changes and used as a base to apply Go backend patterns (middleware, rate limiting, panic recovery) to a separate project from scratch ([Shorty](https://codeberg.org/mazen-dev/shorty)).

## Features

- **Full CRUD REST API for movies** — list, create, view, update, and delete
- **User registration and account activation** flow
- **Per-client rate limiting** — token bucket algorithm (`golang.org/x/time/rate`) keyed by real client IP
- **Panic recovery middleware** — catches panics and returns a clean 500 response instead of crashing
- **PostgreSQL persistence** with SQL migrations
- **Structured routing** via `httprouter`

## API Endpoints

| Method | Path                     | Description                     |
|--------|---------------------------|----------------------------------|
| GET    | `/v1/healthcheck`         | Returns API status               |
| GET    | `/v1/movies`               | Lists movies                     |
| POST   | `/v1/movies`               | Creates a new movie              |
| GET    | `/v1/movies/:id`           | Shows a single movie             |
| PATCH  | `/v1/movies/:id`           | Updates a movie                  |
| DELETE | `/v1/movies/:id`           | Deletes a movie                  |
| POST   | `/v1/users`                 | Registers a new user             |
| PUT    | `/v1/users/activated`      | Activates a user account         |

## Getting Started

### Prerequisites

- Go 1.2x+
- Docker (for running PostgreSQL locally)

### Setup

```bash
# clone the repo
git clone https://codeberg.org/mazen-dev/greenlight.git
cd greenlight

# start PostgreSQL
docker compose up -d

# run migrations
# (adjust to whatever migration tool/command you use, e.g. migrate)

# run the API
go run ./cmd/api
```

> Fill in exact env var names / DB DSN flag and the migration command once confirmed — matching Shorty's setup style above.

## Example Usage

```bash
curl http://localhost:8080/v1/healthcheck

curl http://localhost:8080/v1/movies
```

## Tech Stack

Go · httprouter · PostgreSQL · Docker Compose
