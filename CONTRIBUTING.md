# Contributing to SynapseFS

Thank you for contributing to SynapseFS.

SynapseFS is both a correctness-critical distributed file synchronization system
and a systems research project. Contributions should preserve correctness,
reproducibility, and clear experimental evidence.

## Development Requirements

SynapseFS currently requires:

- Python 3.13+
- Git
- `uv`
- the development environment defined by `pyproject.toml` and `uv.lock`

Synchronize the development environment with:

```bash
uv sync --locked --group dev
```
