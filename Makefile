.PHONY: setup up down backend frontend test lint

setup:
	cp -n .env.example .env || true
	docker compose build

up:
	docker compose up -d

down:
	docker compose down

backend:
	cd apps/backend && uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

frontend:
	cd apps/frontend && npm run dev

test:
	cd apps/backend && pytest

lint:
	cd apps/backend && ruff check .
