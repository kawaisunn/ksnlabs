# CAIT Action Logging — Integration Guide
# Apply to: C:\dev\ksnlabs\aggdb\api\main.py (on Intrusion)
# Prerequisite: action_log.py must be in the same directory
# Status: WRITTEN, UNTESTED

## Change 1: Add import (line ~14, after other imports)

After the line:
    import db

Add:
    import action_log

---

## Change 2: Log batch commits (in commit_queue function, before the return)

Find the line:
    return CommitResult(

Add BEFORE it:
    # ── CAIT Action Log ──
    try:
        action_log.log_commit(
            batch_id=batch_id,
            user=sorted_records[0].fields.get("CreatedBy", "unknown") if sorted_records else "unknown",
            records=sorted_records,
            committed=committed,
            errors=errors,
            details=details,
        )
    except Exception:
        pass  # never break the API

---

## Change 3: Log site creation (in create_site endpoint, after successful insert)

Find the endpoint:
    @app.post("/api/sites")

After the successful site creation (after the try block inserts into Sites),
add logging. The exact location depends on the endpoint structure —
look for where `committed += 1` or the success return happens.

Add:
    try:
        action_log.log_site_create(
            user=body.CreatedBy or "unknown",
            site_id=body.SiteID,
            fields=body.model_dump(),
        )
    except Exception:
        pass

---

## Change 4: Log record edits (in PUT /api/recs/{rec_id})

After a successful update, add:
    try:
        action_log.log_rec_edit(
            user="edit",  # no user field in PUT payload currently
            rec_id=rec_id,
            changes=body.model_dump(exclude_unset=True),
        )
    except Exception:
        pass

---

## Verification

After applying and restarting the API:
1. Create a test record through ToiQa
2. Check: C:\dev\_DOCKSN\ITD_OUT\cait_shadow\actions\actions_YYYYMMDD.jsonl
3. Should contain one JSONL line per commit with full field data

## Output Format (example)

{"timestamp":"2026-03-14T15:30:00","action":"commit_batch","user":"rkanderson","result":"success","batch_id":"abc-123","record_count":2,"records":[{"table":"Rec","fields":{"RecID":"D3_001_QAMS_2025","RecTypeID":10,"SiteID":"Ad-62-s","RecDate":"2025-06-15","Title":"QAMS Cert Letter","CreatedBy":"rkanderson"}},{"table":"QAMS","fields":{"RecID":"D3_001_QAMS_2025","SiteID":"Ad-62-s","QualExpDate":"2026-06-15","ApprovedFor":"Base, Subbase"}}],"commit_details":[{"id":"rec_1","table":"Rec","key":"D3_001_QAMS_2025","ok":true}]}
