"""
ITD_AggDB FastAPI backend.
Serves the data entry frontend for Rebecca and connects to IGS-Intrusion\\SQLEXPRESS.

Endpoints aligned to actual v2 schema (post Docs→Rec rename, 63 tables).
Link-table pattern: RecLink, StatusLink, TestResultLink, QAMSLink, etc.

Usage:
    python main.py
    # or: uvicorn main:app --host 127.0.0.1 --port 8000 --reload
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import uuid
from datetime import datetime, date
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
import db
from models import (
    SiteRead, SiteDetail, SiteCreate,
    RecRead, RecCreate, RecUpdate, RecLinkCreate,
    TestResultRead, TestResultCreate,
    QAMSRead, QAMSCreate,
    AccessRead,
    TestType, RecType, Status, Commodity, MaterialType,
    CommitRequest, CommitResult,
)
import os

app = FastAPI(
    title="ITD_AggDB API",
    description="Aggregate Materials Database — RP-315 / FHWA / Idaho Geological Survey",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Serve frontend HTML from parent directory
FRONTEND_DIR = os.path.join(os.path.dirname(__file__), "..", "frontend")


# ╔══════════════════════════════════════════════════════════════╗
# ║  HEALTH                                                      ║
# ╚══════════════════════════════════════════════════════════════╝
@app.get("/api/ping")
def ping():
    """No-DB connectivity test."""
    return {"status": "ok", "msg": "API is alive, no DB call"}

@app.get("/api/health")
def health():
    try:
        import logging
        logging.warning("health: about to call db.health_check()")
        info = db.health_check()
        logging.warning("health: got response")
        return info
    except Exception as e:
        raise HTTPException(status_code=503, detail=str(e))


# ╔══════════════════════════════════════════════════════════════╗
# ║  LOOKUPS                                                     ║
# ╚══════════════════════════════════════════════════════════════╝
@app.get("/api/lut/testtypes", response_model=list[TestType])
def get_test_types():
    return db.fetch_all(
        "SELECT TestTypeID, TestCode, TestName, StandardRef, "
        "TestCategory, ApplicableSpecs, IsVisible "
        "FROM LU_TestType WHERE IsVisible = 1 ORDER BY SortOrder"
    )

@app.get("/api/lut/rectypes", response_model=list[RecType])
def get_rec_types():
    return db.fetch_all(
        "SELECT RecTypeID, RecTypeName, SortOrder "
        "FROM LU_RecType WHERE IsVisible = 1 ORDER BY SortOrder"
    )

@app.get("/api/lut/statuses", response_model=list[Status])
def get_statuses():
    return db.fetch_all(
        "SELECT StatusID, StatusName FROM LU_Status ORDER BY SortOrder"
    )

@app.get("/api/lut/commodities", response_model=list[Commodity])
def get_commodities():
    return db.fetch_all(
        "SELECT CommodityID, CommodityName FROM LU_Commodity ORDER BY SortOrder"
    )

@app.get("/api/lut/materialtypes", response_model=list[MaterialType])
def get_material_types():
    return db.fetch_all(
        "SELECT MaterialTypeID, MaterialTypeName, Description "
        "FROM LU_MaterialType ORDER BY SortOrder"
    )


# ╔══════════════════════════════════════════════════════════════╗
# ║  SITES — LIST                                                ║
# ╚══════════════════════════════════════════════════════════════╝
@app.get("/api/sites", response_model=list[SiteRead])
def list_sites():
    """List all sites with current status (from StatusLink)."""
    return db.fetch_all("""
        SELECT s.SiteID, s.SiteName, s.lonNAD83IDTM, s.latNAD83IDTM,
               s.PLSSp, s.Notes, s.CreatedDate, s.CreatedBy,
               ls.StatusName AS CurrentStatus,
               CONVERT(varchar, sl.EffectiveDate, 23) AS StatusEffective
        FROM Sites s
        LEFT JOIN StatusLink sl ON s.SiteID = sl.SiteID
            AND sl.EndDate IS NULL  -- current status = no end date
        LEFT JOIN LU_Status ls ON sl.StatusID = ls.StatusID
        ORDER BY s.SiteID
    """)


# ╔══════════════════════════════════════════════════════════════╗
# ║  SITES — DETAIL                                              ║
# ╚══════════════════════════════════════════════════════════════╝
@app.get("/api/sites/{site_id}")
def get_site_detail(site_id: str):
    """Full site detail: site + access + recs + tests + QAMS."""
    site = db.fetch_one("""
        SELECT s.SiteID, s.SiteName, s.lonNAD83IDTM, s.latNAD83IDTM,
               s.PLSSp, s.Notes, s.CreatedDate, s.CreatedBy,
               ls.StatusName AS CurrentStatus,
               CONVERT(varchar, sl.EffectiveDate, 23) AS StatusEffective
        FROM Sites s
        LEFT JOIN StatusLink sl ON s.SiteID = sl.SiteID AND sl.EndDate IS NULL
        LEFT JOIN LU_Status ls ON sl.StatusID = ls.StatusID
        WHERE s.SiteID = ?
    """, [site_id])
    if not site:
        raise HTTPException(status_code=404, detail=f"Site {site_id} not found")

    access_rows = db.fetch_all(
        "SELECT AccessID, SiteID, FieldVerified, Comments FROM Access WHERE SiteID = ?",
        [site_id]
    )

    # Recs linked via RecLink (RecLink.RelateID = SiteID)
    rec_rows = db.fetch_all("""
        SELECT r.RecID, r.RecTypeID, rt.RecTypeName,
               r.RecLink, r.RecNumber, r.Title, r.RecDate,
               r.Notes, r.CreatedDate, r.CreatedBy
        FROM Rec r
        JOIN RecLink rl ON r.RecID = rl.RecID
        LEFT JOIN LU_RecType rt ON r.RecTypeID = rt.RecTypeID
        WHERE rl.RelateID = ?
        ORDER BY r.RecDate DESC
    """, [site_id])

    test_rows = db.fetch_all("""
        SELECT tr.TestResultID, tr.SiteID, tr.TestTypeID,
               tt.TestCode, tt.TestName, tt.StandardRef,
               tr.CommodityID, tr.MaterialTypeID,
               tr.TestValue, tr.TestDate, tr.LabName,
               tr.SampleID, tr.Notes, tr.PassFail
        FROM TestResult tr
        JOIN LU_TestType tt ON tr.TestTypeID = tt.TestTypeID
        WHERE tr.SiteID = ?
        ORDER BY tr.TestDate DESC
    """, [site_id])

    qams_rows = db.fetch_all("""
        SELECT q.QAMSID, q.RecID, q.SiteID,
               q.QualExpDate, q.LastRenewalDate,
               q.ApprovedFor, q.ConditionalUses,
               q.CertLetterRecID, q.Notes
        FROM QAMS q WHERE q.SiteID = ?
        ORDER BY q.QualExpDate DESC
    """, [site_id])

    return {
        "site": site,
        "access": access_rows,
        "recs": rec_rows,
        "test_results": test_rows,
        "qams": qams_rows,
    }


# ╔══════════════════════════════════════════════════════════════╗
# ║  SITES — CREATE                                              ║
# ╚══════════════════════════════════════════════════════════════╝
@app.post("/api/sites")
def create_site(body: SiteCreate):
    """Insert a new site + optional StatusLink."""
    existing = db.fetch_one("SELECT SiteID FROM Sites WHERE SiteID = ?", [body.SiteID])
    if existing:
        raise HTTPException(status_code=409, detail=f"SiteID '{body.SiteID}' already exists")

    now = datetime.now()
    db.execute("""
        INSERT INTO Sites (SiteID, SiteName, lonNAD83IDTM, latNAD83IDTM,
                           PLSSp, Notes, CreatedDate, CreatedBy)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    """, [body.SiteID, body.SiteName, body.lonNAD83IDTM, body.latNAD83IDTM,
          body.PLSSp, body.Notes, now, body.CreatedBy])

    # Create StatusLink if StatusID provided
    if body.StatusID:
        sl_id = db.next_id('StatusLink', 'StatusLinkID')
        db.execute("""
            INSERT INTO StatusLink (StatusLinkID, SiteID, StatusID, EffectiveDate)
            VALUES (?, ?, ?, ?)
        """, [sl_id, body.SiteID, body.StatusID, now.date()])

    # Auto-link an existing Rec (e.g. temp audit doc) if LinkRecID provided
    linked_rec = None
    if body.LinkRecID:
        rec = db.fetch_one("SELECT RecID FROM Rec WHERE RecID = ?", [body.LinkRecID])
        if rec:
            rl_id = db.next_id('RecLink', 'RecLinkID')
            db.execute(
                "INSERT INTO RecLink (RecLinkID, RecID, RelateID) VALUES (?, ?, ?)",
                [rl_id, body.LinkRecID, body.SiteID]
            )
            linked_rec = body.LinkRecID

    return {"success": True, "SiteID": body.SiteID, "LinkedRecID": linked_rec}


# ╔══════════════════════════════════════════════════════════════╗
# ║  REC — CREATE                                                ║
# ╚══════════════════════════════════════════════════════════════╝
@app.post("/api/recs")
def create_rec(body: RecCreate):
    """Insert Rec + RecLink to site."""
    existing = db.fetch_one("SELECT RecID FROM Rec WHERE RecID = ?", [body.RecID])
    if existing:
        raise HTTPException(status_code=409, detail=f"RecID '{body.RecID}' already exists")

    # Verify SiteID exists
    site = db.fetch_one("SELECT SiteID FROM Sites WHERE SiteID = ?", [body.SiteID])
    if not site:
        raise HTTPException(status_code=404, detail=f"SiteID '{body.SiteID}' not found")

    now = datetime.now()
    db.execute("""
        INSERT INTO Rec (RecID, RecTypeID, RecLink, RecNumber, Title,
                         RecDate, Notes, CreatedDate, CreatedBy)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, [body.RecID, body.RecTypeID, body.RecLink, body.RecNumber,
          body.Title, body.RecDate, body.Notes, now, body.CreatedBy])

    # RecLink: connect Rec to Site
    rl_id = db.next_id('RecLink', 'RecLinkID')
    db.execute("""
        INSERT INTO RecLink (RecLinkID, RecID, RelateID) VALUES (?, ?, ?)
    """, [rl_id, body.RecID, body.SiteID])

    return {"success": True, "RecID": body.RecID}


# ╔══════════════════════════════════════════════════════════════╗
# ║  REC — LIST / GET / UPDATE                                   ║
# ╚══════════════════════════════════════════════════════════════╝
@app.get("/api/recs")
def list_recs():
    """List all Rec entries with their type name."""
    return db.fetch_all("""
        SELECT r.RecID, r.RecTypeID, rt.RecTypeName,
               r.RecLink, r.RecNumber, r.Title, r.RecDate,
               r.Notes, r.CreatedDate, r.CreatedBy
        FROM Rec r
        LEFT JOIN LU_RecType rt ON r.RecTypeID = rt.RecTypeID
        ORDER BY r.RecDate DESC
    """)

@app.get("/api/recs/{rec_id}")
def get_rec(rec_id: str):
    """Get a single Rec by ID with linked sites."""
    rec = db.fetch_one("""
        SELECT r.RecID, r.RecTypeID, rt.RecTypeName,
               r.RecLink, r.RecNumber, r.Title, r.RecDate,
               r.Notes, r.CreatedDate, r.CreatedBy
        FROM Rec r
        LEFT JOIN LU_RecType rt ON r.RecTypeID = rt.RecTypeID
        WHERE r.RecID = ?
    """, [rec_id])
    if not rec:
        raise HTTPException(status_code=404, detail=f"RecID '{rec_id}' not found")
    # Get linked sites
    links = db.fetch_all("""
        SELECT rl.RecLinkID, rl.RelateID AS SiteID, s.SiteName
        FROM RecLink rl
        LEFT JOIN Sites s ON rl.RelateID = s.SiteID
        WHERE rl.RecID = ?
    """, [rec_id])
    return {"rec": rec, "linked_sites": links}

@app.put("/api/recs/{rec_id}")
def update_rec(rec_id: str, body: RecUpdate):
    """Update mutable fields on an existing Rec."""
    existing = db.fetch_one("SELECT RecID FROM Rec WHERE RecID = ?", [rec_id])
    if not existing:
        raise HTTPException(status_code=404, detail=f"RecID '{rec_id}' not found")

    updates = []
    params = []
    for field, col in [
        ("RecTypeID", "RecTypeID"), ("RecLink", "RecLink"),
        ("RecNumber", "RecNumber"), ("Title", "Title"),
        ("RecDate", "RecDate"), ("Notes", "Notes"),
    ]:
        val = getattr(body, field, None)
        if val is not None:
            updates.append(f"[{col}] = ?")
            params.append(val)

    if not updates:
        return {"success": True, "updated": 0, "RecID": rec_id}

    params.append(rec_id)
    db.execute(f"UPDATE Rec SET {', '.join(updates)} WHERE RecID = ?", params)
    return {"success": True, "updated": 1, "RecID": rec_id}


# ╔══════════════════════════════════════════════════════════════╗
# ║  RECLINK — CREATE                                            ║
# ╚══════════════════════════════════════════════════════════════╝
@app.post("/api/reclinks")
def create_reclink(body: RecLinkCreate):
    """Link an existing Rec to an existing Site."""
    rec = db.fetch_one("SELECT RecID FROM Rec WHERE RecID = ?", [body.RecID])
    if not rec:
        raise HTTPException(status_code=404, detail=f"RecID '{body.RecID}' not found")
    site = db.fetch_one("SELECT SiteID FROM Sites WHERE SiteID = ?", [body.SiteID])
    if not site:
        raise HTTPException(status_code=404, detail=f"SiteID '{body.SiteID}' not found")
    # Check for duplicate
    dup = db.fetch_one(
        "SELECT RecLinkID FROM RecLink WHERE RecID = ? AND RelateID = ?",
        [body.RecID, body.SiteID]
    )
    if dup:
        return {"success": True, "msg": "Link already exists", "RecLinkID": dup["RecLinkID"]}
    rl_id = db.next_id('RecLink', 'RecLinkID')
    db.execute(
        "INSERT INTO RecLink (RecLinkID, RecID, RelateID) VALUES (?, ?, ?)",
        [rl_id, body.RecID, body.SiteID]
    )
    return {"success": True, "RecLinkID": rl_id}


# ╔══════════════════════════════════════════════════════════════╗
# ║  TEST RESULT — CREATE                                        ║
# ╚══════════════════════════════════════════════════════════════╝
@app.post("/api/testresults")
def create_test_result(body: TestResultCreate):
    """Insert TestResult + optional TestResultLink to Rec."""
    site = db.fetch_one("SELECT SiteID FROM Sites WHERE SiteID = ?", [body.SiteID])
    if not site:
        raise HTTPException(status_code=404, detail=f"SiteID '{body.SiteID}' not found")

    tt = db.fetch_one("SELECT TestTypeID FROM LU_TestType WHERE TestTypeID = ? AND IsVisible = 1",
                       [body.TestTypeID])
    if not tt:
        raise HTTPException(status_code=404, detail=f"TestTypeID {body.TestTypeID} not found or hidden")

    now = datetime.now()
    new_id = db.execute_returning_id("""
        INSERT INTO TestResult (SiteID, TestTypeID, CommodityID, MaterialTypeID,
                                TestValue, TestDate, LabName, SampleID,
                                Notes, CreatedDate, CreatedBy)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, [body.SiteID, body.TestTypeID, body.CommodityID, body.MaterialTypeID,
          body.TestValue, body.TestDate, body.LabName, body.SampleID,
          body.Notes, now, body.CreatedBy])

    # TestResultLink: connect to source Rec if provided
    if body.RecID:
        tr = db.fetch_one(
            "SELECT TestResultID FROM TestResult WHERE id = ?", [new_id]
        )
        if tr:
            trl_id = db.next_id('TestResultLink', 'TestResultLinkID')
            db.execute("""
                INSERT INTO TestResultLink (TestResultLinkID, TestResultID, RecID) VALUES (?, ?, ?)
            """, [trl_id, tr["TestResultID"], body.RecID])

    return {"success": True, "id": new_id}


# ╔══════════════════════════════════════════════════════════════╗
# ║  QAMS — CREATE                                               ║
# ╚══════════════════════════════════════════════════════════════╝
@app.post("/api/qams")
def create_qams(body: QAMSCreate):
    """Insert QAMS record + QAMSLink to Rec."""
    site = db.fetch_one("SELECT SiteID FROM Sites WHERE SiteID = ?", [body.SiteID])
    if not site:
        raise HTTPException(status_code=404, detail=f"SiteID '{body.SiteID}' not found")

    now = datetime.now()
    new_id = db.execute_returning_id("""
        INSERT INTO QAMS (RecID, SiteID, QualExpDate, LastRenewalDate,
                          ApprovedFor, ConditionalUses, CertLetterRecID,
                          Notes, CreatedDate, CreatedBy)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, [body.RecID, body.SiteID, body.QualExpDate, body.LastRenewalDate,
          body.ApprovedFor, body.ConditionalUses, body.CertLetterRecID,
          body.Notes, now, body.CreatedBy])

    # QAMSLink: connect to Rec
    qams_row = db.fetch_one("SELECT QAMSID FROM QAMS WHERE id = ?", [new_id])
    if qams_row:
        ql_id = db.next_id('QAMSLink', 'QAMSLinkID')
        db.execute("""
            INSERT INTO QAMSLink (QAMSLinkID, QAMSID, RecID) VALUES (?, ?, ?)
        """, [ql_id, qams_row["QAMSID"], body.RecID])

    return {"success": True, "id": new_id}


# ╔══════════════════════════════════════════════════════════════╗
# ║  BATCH COMMIT                                                ║
# ╚══════════════════════════════════════════════════════════════╝
@app.post("/api/commit", response_model=CommitResult)
def commit_queue(req: CommitRequest):
    """
    Commit a batch of staged records from the frontend queue.
    Processes in dependency order: Sites → Rec → TestResult/QAMS.
    """
    errors = []
    details = []
    committed = 0

    # Sort: Sites first, then Rec, then everything else
    order = {"Sites": 0, "Rec": 1, "TestResult": 2, "QAMS": 3}
    sorted_records = sorted(req.records, key=lambda r: order.get(r.table, 99))

    batch_id = str(uuid.uuid4())
    now = datetime.now()

    for rec in sorted_records:
        try:
            if rec.table == "Sites":
                f = rec.fields
                db.execute("""
                    INSERT INTO Sites (SiteID, SiteName, lonNAD83IDTM, latNAD83IDTM,
                                       PLSSp, Notes, CreatedDate, CreatedBy)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """, [f.get("SiteID"), f.get("SiteName"),
                      f.get("lonNAD83IDTM"), f.get("latNAD83IDTM"),
                      f.get("PLSSp"), f.get("Notes"), now, f.get("CreatedBy")])

                if f.get("StatusID"):
                    sl_id = db.next_id('StatusLink', 'StatusLinkID')
                    db.execute("""
                        INSERT INTO StatusLink (StatusLinkID, SiteID, StatusID, EffectiveDate)
                        VALUES (?, ?, ?, ?)
                    """, [sl_id, f["SiteID"], f["StatusID"], now.date()])

                committed += 1
                details.append({"id": rec.id, "table": "Sites", "key": f["SiteID"], "ok": True})

            elif rec.table == "Rec":
                f = rec.fields
                db.execute("""
                    INSERT INTO Rec (RecID, RecTypeID, RecLink, RecNumber, Title,
                                     RecDate, Notes, CreatedDate, CreatedBy)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, [f.get("RecID"), f.get("RecTypeID"), f.get("RecLink"),
                      f.get("RecNumber"), f.get("Title"), f.get("RecDate"),
                      f.get("Notes"), now, f.get("CreatedBy")])

                if f.get("SiteID"):
                    rl_id = db.next_id('RecLink', 'RecLinkID')
                    db.execute("INSERT INTO RecLink (RecLinkID, RecID, RelateID) VALUES (?, ?, ?)",
                               [rl_id, f["RecID"], f["SiteID"]])

                committed += 1
                details.append({"id": rec.id, "table": "Rec", "key": f["RecID"], "ok": True})

            elif rec.table == "TestResult":
                f = rec.fields
                new_id = db.execute_returning_id("""
                    INSERT INTO TestResult (SiteID, TestTypeID, CommodityID, MaterialTypeID,
                                            TestValue, TestDate, LabName, SampleID,
                                            Notes, CreatedDate, CreatedBy)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, [f.get("SiteID"), f.get("TestTypeID"),
                      f.get("CommodityID"), f.get("MaterialTypeID"),
                      f.get("TestValue"), f.get("TestDate"),
                      f.get("LabName"), f.get("SampleID"),
                      f.get("Notes"), now, f.get("CreatedBy")])

                if f.get("RecID"):
                    tr = db.fetch_one("SELECT TestResultID FROM TestResult WHERE id = ?", [new_id])
                    if tr:
                        trl_id = db.next_id('TestResultLink', 'TestResultLinkID')
                        db.execute("INSERT INTO TestResultLink (TestResultLinkID, TestResultID, RecID) VALUES (?, ?, ?)",
                                   [trl_id, tr["TestResultID"], f["RecID"]])

                committed += 1
                details.append({"id": rec.id, "table": "TestResult", "key": new_id, "ok": True})

            elif rec.table == "QAMS":
                f = rec.fields
                new_id = db.execute_returning_id("""
                    INSERT INTO QAMS (RecID, SiteID, QualExpDate, LastRenewalDate,
                                      ApprovedFor, ConditionalUses, CertLetterRecID,
                                      Notes, CreatedDate, CreatedBy)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, [f.get("RecID"), f.get("SiteID"),
                      f.get("QualExpDate"), f.get("LastRenewalDate"),
                      f.get("ApprovedFor"), f.get("ConditionalUses"),
                      f.get("CertLetterRecID"), f.get("Notes"), now, f.get("CreatedBy")])

                qams_row = db.fetch_one("SELECT QAMSID FROM QAMS WHERE id = ?", [new_id])
                if qams_row and f.get("RecID"):
                    ql_id = db.next_id('QAMSLink', 'QAMSLinkID')
                    db.execute("INSERT INTO QAMSLink (QAMSLinkID, QAMSID, RecID) VALUES (?, ?, ?)",
                               [ql_id, qams_row["QAMSID"], f["RecID"]])

                committed += 1
                details.append({"id": rec.id, "table": "QAMS", "key": new_id, "ok": True})

            else:
                errors.append(f"Unknown table '{rec.table}' for record {rec.id}")
                details.append({"id": rec.id, "table": rec.table, "ok": False,
                                "error": f"Unknown table"})

        except Exception as e:
            errors.append(f"{rec.table} {rec.id}: {str(e)}")
            details.append({"id": rec.id, "table": rec.table, "ok": False, "error": str(e)})

    return CommitResult(
        success=len(errors) == 0,
        committed=committed,
        errors=errors,
        details=details,
    )


# ╔══════════════════════════════════════════════════════════════╗
# ║  FRONTEND SERVE                                              ║
# ╚══════════════════════════════════════════════════════════════╝
@app.get("/")
def serve_frontend():
    """Serve the frontend HTML."""
    html_path = os.path.join(FRONTEND_DIR, "ITD_AggDB_v4.html")
    if os.path.exists(html_path):
        return FileResponse(html_path, media_type="text/html")
    return {"message": "Frontend not found. Place ITD_AggDB_v4.html in ../frontend/"}


if __name__ == "__main__":
    import uvicorn
    print("=" * 60)
    print("  ITD_AggDB API Server — RP-315")
    print("  http://127.0.0.1:8000")
    print("  http://127.0.0.1:8000/docs  (Swagger UI)")
    print("=" * 60)
    uvicorn.run(app, host="0.0.0.0", port=8000)
