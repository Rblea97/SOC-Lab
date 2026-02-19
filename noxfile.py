"""Nox sessions — MPS quality gates scoped to tools/."""

import nox

nox.options.default_venv_backend = "uv"
nox.options.reuse_existing_virtualenvs = True

PYTHON = "3.11"
SRC = ["tools"]


@nox.session(python=PYTHON)
def fmt(session: nox.Session) -> None:
    """Run ruff formatter."""
    session.install("ruff>=0.9")
    session.run("ruff", "format", *SRC)


@nox.session(python=PYTHON)
def lint(session: nox.Session) -> None:
    """Run ruff linter."""
    session.install("ruff>=0.9")
    session.run("ruff", "check", *SRC)


@nox.session(python=PYTHON)
def type(session: nox.Session) -> None:
    """Run pyright static type checker."""
    session.install(
        "pyright>=1.1.390",
        "pytest>=7.4",
        "requests>=2.31",
        "pyyaml>=6.0",
        "types-requests>=2.31",
        "types-PyYAML>=6.0",
    )
    session.run("pyright", *SRC)


@nox.session(python=PYTHON)
def test(session: nox.Session) -> None:
    """Run pytest test suite."""
    session.install("pytest>=7.4", "requests>=2.31", "pyyaml>=6.0")
    session.run("pytest", "tools/tests", *session.posargs, env={"PYTHONPATH": "tools"})


@nox.session(python=PYTHON)
def audit(session: nox.Session) -> None:
    """Run pip-audit against pinned requirements."""
    session.install("pip-audit>=2.7")
    session.run("pip-audit", "-r", "requirements-audit.txt")


@nox.session(python=PYTHON)
def all(session: nox.Session) -> None:
    """Run all quality gates in sequence."""
    session.notify("fmt")
    session.notify("lint")
    session.notify("type")
    session.notify("test")
    session.notify("audit")
