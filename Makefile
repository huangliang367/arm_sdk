.PHONY: all repo manifest docker-setup docker-run build

# ============================================================
# Proxy (optional) — accelerates repo sync and git clones
# Usage: make PROXY=http://proxy:port all
# ============================================================
PROXY ?=
ifneq ($(PROXY),)
export HTTP_PROXY  := $(PROXY)
export HTTPS_PROXY := $(PROXY)
export http_proxy  := $(PROXY)
export https_proxy := $(PROXY)
endif

# ============================================================
# Default target: run the full pipeline
# ============================================================
all: repo manifest docker-setup docker-run build
	@echo "All steps completed."

# ============================================================
# Step 1: Check and install repo tool
# ============================================================
repo:
	@echo "==> Checking repo tool..."
	@if command -v repo >/dev/null 2>&1; then \
		echo "repo already installed: $$(which repo)"; \
	else \
		echo "repo not found, installing..."; \
		sudo curl -sSL -o /usr/local/bin/repo https://storage.googleapis.com/git-repo-downloads/repo; \
		sudo chmod a+x /usr/local/bin/repo; \
		echo "repo installed successfully."; \
	fi

# ============================================================
# Step 2: Pull manifest repository
# ============================================================
manifest: repo
	@echo "==> Initializing manifest repository..."
	@if [ -d .repo ]; then \
		echo ".repo already exists, skipping init. Running sync..."; \
	else \
		repo init -u git@github.com:huangliang367/manifest.git; \
	fi
	@echo "==> Syncing repositories..."
	repo sync
	@echo "==> Manifest pull complete."

# ============================================================
# Step 3: Check/install Docker and build image
# ============================================================
docker-setup: manifest
	@echo "==> Checking Docker..."
	@if command -v docker >/dev/null 2>&1; then \
		echo "Docker already installed: $$(docker --version)"; \
	else \
		echo "Docker not found, installing..."; \
		if [ -f /etc/debian_version ]; then \
			sudo apt-get update && sudo apt-get install -y docker.io; \
		elif [ -f /etc/redhat-release ]; then \
			sudo yum install -y docker; \
		else \
			echo "ERROR: Unsupported distribution. Please install Docker manually."; \
			exit 1; \
		fi; \
		echo "Docker installed successfully."; \
	fi
	@echo "==> Building Docker image..."
	@if [ -x dockerfile/build.sh ]; then \
		bash dockerfile/build.sh; \
	else \
		echo "ERROR: dockerfile/build.sh not found or not executable."; \
		exit 1; \
	fi
	@echo "==> Docker setup complete."

# ============================================================
# Step 4: Run Docker container
# ============================================================
docker-run: docker-setup
	@echo "==> Starting Docker environment..."
	@if [ -x dockerfile/run.sh ]; then \
		bash dockerfile/run.sh; \
	else \
		echo "ERROR: dockerfile/run.sh not found or not executable."; \
		exit 1; \
	fi
	@echo "==> Docker environment started."

# ============================================================
# Step 5: Build project
# ============================================================
build: docker-run manifest
	@echo "==> Building project..."
	@if [ -x scripts/build.sh ]; then \
		bash scripts/build.sh; \
	else \
		echo "ERROR: scripts/build.sh not found or not executable."; \
		exit 1; \
	fi
	@echo "==> Build complete."
