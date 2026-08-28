UV ?= uv

.PHONY: sync lint format format-check hooks smoke check clean

sync:
	$(UV) sync --group dev

lint:
	$(UV) run ruff check .

format:
	$(UV) run ruff format .

format-check:
	$(UV) run ruff format --check .

hooks:
	$(UV) run pre-commit run --all-files

smoke:
	$(UV) run python -c "import synapsefs; print(synapsefs.__version__)"

check: lint format-check smoke

clean:
	rm -rf .ruff_cache
	rm -rf .pytest_cache
	rm -rf .mypy_cache
	find . -type d -name __pycache__ -prune -exec rm -rf {} +
