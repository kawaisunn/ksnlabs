"""
action_log.py — CAIT Action Logger for ITD_AggDB
Captures every write operation (commit, create site, edit rec) as structured 
JSONL for CAIT Phase 3 training data.

Records WHAT was done, not HOW. See CAIT_SPEC.json dataSecurityModel —
these logs contain ITD data and follow the same access restrictions.

Output: C:\dev\_DOCKSN\ITD_OUT\cait_shadow\actions\actions_YYYYMMDD.jsonl

Status: WRITTEN, UNTESTED — needs deployment to Intrusion API
Author: Opus (2026-03-14)
"""

import json
import os
from datetime import datetime
from pathlib import Path

# Default output directory — matches DOCKSN ITD_OUT structure
ACTION_LOG_DIR = os.environ.get(
    "CAIT_ACTION_LOG_DIR",
    r"C:\dev\_DOCKSN\ITD_OUT\cait_shadow\actions"
)


def _ensure_dir():
    """Create action log directory if needed."""
    Path(ACTION_LOG_DIR).mkdir(parents=True, exist_ok=True)


def _log_path() -> str:
    """Daily log file path."""
    return os.path.join(
        ACTION_LOG_DIR,
        f"actions_{datetime.now().strftime('%Y%m%d')}.jsonl"
    )


def log_action(
    action: str,
    user: str,
    records: list = None,
    fields: dict = None,
    batch_id: str = None,
    result: str = "success",
    details: list = None,
    error: str = None,
):
    """
    Write a single action log entry as JSONL.
    
    Args:
        action: Type of action (commit_batch, create_site, edit_rec, create_rec, etc.)
        user: Username from CreatedBy field
        records: List of record dicts from commit queue (for batch commits)
        fields: Single record's field dict (for individual operations)
        batch_id: UUID for batch commits
        result: "success" or "partial" or "failed"
        details: Commit details array from CommitResult
        error: Error message if failed
    """
    try:
        _ensure_dir()
        
        entry = {
            "timestamp": datetime.now().isoformat(),
            "action": action,
            "user": user,
            "result": result,
        }
        
        if batch_id:
            entry["batch_id"] = batch_id
        
        if records:
            # For batch commits: log each record's table and fields
            entry["record_count"] = len(records)
            entry["records"] = []
            for rec in records:
                rec_entry = {
                    "table": rec.get("table") if isinstance(rec, dict) else getattr(rec, "table", None),
                    "fields": rec.get("fields") if isinstance(rec, dict) else (
                        getattr(rec, "fields", None) if hasattr(rec, "fields") else None
                    ),
                }
                # Convert Pydantic fields dict if needed
                if hasattr(rec_entry["fields"], "items"):
                    rec_entry["fields"] = dict(rec_entry["fields"])
                entry["records"].append(rec_entry)
        
        if fields:
            entry["fields"] = fields
        
        if details:
            entry["commit_details"] = details
        
        if error:
            entry["error"] = error
        
        # Append to daily log
        with open(_log_path(), "a", encoding="utf-8") as f:
            f.write(json.dumps(entry, default=str) + "\n")
    
    except Exception as e:
        # Action logging must NEVER break the API
        import logging
        logging.getLogger("action_log").warning(f"Action log write failed: {e}")


def log_commit(batch_id: str, user: str, records: list, committed: int, 
               errors: list, details: list):
    """Convenience wrapper for commit_queue logging."""
    log_action(
        action="commit_batch",
        user=user,
        records=[{"table": r.table, "fields": r.fields} for r in records],
        batch_id=batch_id,
        result="success" if not errors else "partial" if committed > 0 else "failed",
        details=details,
        error="; ".join(errors) if errors else None,
    )


def log_site_create(user: str, site_id: str, fields: dict):
    """Convenience wrapper for site creation logging."""
    log_action(
        action="create_site",
        user=user,
        fields={"SiteID": site_id, **fields},
    )


def log_rec_edit(user: str, rec_id: str, changes: dict):
    """Convenience wrapper for record edit logging."""
    log_action(
        action="edit_rec",
        user=user or "unknown",
        fields={"RecID": rec_id, "changes": changes},
    )
