#==================================================================================== #
# HELPERS
# ==================================================================================== #

set dotenv-load := true

DSN := env_var('DSN')

confirm:
	@echo -n 'Are you sure? [y/N] ' && read ans && [ ${ans:-N} = y ]

# ==================================================================================== #
# DEVELOPMENT
# ==================================================================================== #

# Run the compose services
compose-up: 
	@echo 'starting services...'
	podman-compose up -d

# Stop the compose services
compose-down: 
	@echo 'stopping services...'
	podman-compose down

# Open the database with psql
db-psql: 
	@echo 'entring database...'
	psql $DSN

# Perform the migrations on the database
db-migrations-create name: 
	@echo 'creating migration files for {{name}}...'
	migrate create -seq -ext=.sql -dir=./migrations {{name}}

# Perform the migrations on the database
db-migrations-up: confirm 
	@echo 'performing migrations on database...'
	migrate -path ./migrations -database $DSN up

# Running the api
run-api:
	@echo 'running the api...'
	go run ./cmd/api -db-dsn=$DSN

# ==================================================================================== #
# QUALITY CONTROL
# ==================================================================================== #

# tidy: tidy module dependencies and format all .go files
tidy:
	@echo 'Tidying module dependencies...'
	go mod tidy
	@echo 'Verifying and vendoring module dependencies...'
	go mod verify
	go mod vendor
	@echo 'Formatting .go files...'
	go fmt ./...

# audit: run quality control checks
audit:
	@echo 'Checking module dependencies...'
	go mod tidy -diff
	go mod verify
	@echo 'Vetting code...'
	go vet ./...
	go tool staticcheck ./...
	@echo 'Running tests...'
	go test -race -vet=off ./...

# ==================================================================================== #
# BUILD
# ==================================================================================== #

# build the api
build-api:
	@echo 'Building cmd/api...'
	go build -ldflags='-s' -o=./bin/api ./cmd/api
