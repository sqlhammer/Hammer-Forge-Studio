"""generate_tickets.py — Write/clean ephemeral tickets for test harness."""

import shutil
from pathlib import Path

from .ticket_templates import TICKETS


def create_test_tickets(repo_root: Path) -> Path:
    """Write all fake tickets to tickets/_test/. Returns the directory path."""
    test_dir = repo_root / "tickets" / "_test"
    # Clean slate
    if test_dir.exists():
        shutil.rmtree(test_dir)
    test_dir.mkdir(parents=True, exist_ok=True)

    for ticket_id, content in TICKETS.items():
        path = test_dir / f"{ticket_id}.md"
        path.write_text(content, encoding="utf-8")

    return test_dir


def cleanup_test_tickets(repo_root: Path):
    """Remove tickets/_test/ directory entirely."""
    test_dir = repo_root / "tickets" / "_test"
    if test_dir.exists():
        shutil.rmtree(test_dir)


def mark_ticket_done(repo_root: Path, ticket_id: str):
    """Update a ticket's status from OPEN to DONE in its frontmatter."""
    path = repo_root / "tickets" / "_test" / f"{ticket_id}.md"
    if not path.exists():
        return
    text = path.read_text(encoding="utf-8")
    text = text.replace("status: OPEN", "status: DONE", 1)
    text = text.replace("status: IN_PROGRESS", "status: DONE", 1)
    path.write_text(text, encoding="utf-8")
