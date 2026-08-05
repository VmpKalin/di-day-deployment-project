IMAGE      := di-test-project:local
CONTAINER  := di-test-project
VERSION    := 0.2.0
SHA        := $(shell git rev-parse --short HEAD)
BRANCH     := $(shell git rev-parse --abbrev-ref HEAD)
BUILD_TIME := $(shell date -u +%Y-%m-%dT%H:%M:%SZ)

.PHONY: build run stop logs verify

build:
	docker build \
		--build-arg VITE_APP_VERSION=$(VERSION) \
		--build-arg VITE_GIT_SHA=$(SHA) \
		--build-arg VITE_GIT_BRANCH=$(BRANCH) \
		--build-arg VITE_BUILD_TIME=$(BUILD_TIME) \
		-t $(IMAGE) .

run:
	docker run -d --rm --name $(CONTAINER) -p 8080:8080 $(IMAGE)

stop:
	docker rm -f $(CONTAINER)

logs:
	docker logs -f $(CONTAINER)

# Vite inlines env vars into a hashed JS bundle, so the SHA lives in the
# JS asset referenced by index.html, not in the HTML itself.
verify:
	@body=$$(curl -sf http://localhost:8080/healthz) && [ "$$body" = "ok" ] \
		|| { echo "FAIL: /healthz did not return ok"; exit 1; }
	@html=$$(curl -s http://localhost:8080/); \
	js=$$(echo "$$html" | grep -o '/assets/[^"]*\.js' | head -1); \
	if echo "$$html" | grep -q "$(SHA)"; then :; \
	elif [ -n "$$js" ] && curl -s "http://localhost:8080$$js" | grep -q "$(SHA)"; then :; \
	else \
		echo "FAIL: SHA $(SHA) not found in / or $$js —" \
			"build arg did not reach Vite — check ARG -> ENV promotion in the Dockerfile"; \
		exit 1; \
	fi
	@echo "OK: healthz ok, SHA $(SHA) present in served bundle"
