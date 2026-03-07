"""
Pydantic models for ITD_AggDB API.
Aligned to actual v2 schema on IGS-Intrusion\\SQLEXPRESS.
"""
from pydantic import BaseModel, Field
from datetime import date, datetime
from typing import Optional


# ── Lookup models ──────────────────────────────────────────────
class TestType(BaseModel):
    TestTypeID: int
    TestCode: str
    TestName: str
    StandardRef: Optional[str] = None
    TestCategory: Optional[str] = None
    ApplicableSpecs: Optional[str] = None
    IsVisible: bool = True

class RecType(BaseModel):
    RecTypeID: int
    RecTypeName: Optional[str] = None
    SortOrder: int = 0

class Status(BaseModel):
    StatusID: int
    StatusName: Optional[str] = None

class Commodity(BaseModel):
    CommodityID: int
    CommodityName: Optional[str] = None

class MaterialType(BaseModel):
    MaterialTypeID: int
    MaterialTypeName: str
    Description: Optional[str] = None


# ── Core entity models (read) ─────────────────────────────────
class SiteRead(BaseModel):
    SiteID: str
    SiteName: Optional[str] = None
    lonNAD83IDTM: Optional[float] = None
    latNAD83IDTM: Optional[float] = None
    PLSSp: Optional[str] = None
    Notes: Optional[str] = None
    CreatedDate: Optional[datetime] = None
    CreatedBy: Optional[str] = None
    # joined fields
    CurrentStatus: Optional[str] = None
    StatusEffective: Optional[str] = None

class RecRead(BaseModel):
    RecID: str
    RecTypeID: int
    RecTypeName: Optional[str] = None
    RecLink: Optional[str] = None
    RecNumber: Optional[str] = None
    Title: Optional[str] = None
    RecDate: Optional[date] = None
    Notes: Optional[str] = None
    CreatedDate: Optional[datetime] = None
    CreatedBy: Optional[str] = None

class TestResultRead(BaseModel):
    TestResultID: int
    SiteID: str
    TestTypeID: int
    TestCode: Optional[str] = None
    TestName: Optional[str] = None
    StandardRef: Optional[str] = None
    CommodityID: Optional[int] = None
    MaterialTypeID: Optional[int] = None
    TestValue: Optional[str] = None
    TestDate: Optional[date] = None
    LabName: Optional[str] = None
    SampleID: Optional[str] = None
    Notes: Optional[str] = None
    PassFail: Optional[str] = None

class QAMSRead(BaseModel):
    QAMSID: int
    RecID: str
    SiteID: str
    QualExpDate: Optional[date] = None
    LastRenewalDate: Optional[date] = None
    ApprovedFor: Optional[str] = None
    ConditionalUses: Optional[str] = None
    CertLetterRecID: Optional[str] = None
    Notes: Optional[str] = None

class AccessRead(BaseModel):
    AccessID: str
    SiteID: Optional[str] = None
    FieldVerified: Optional[bool] = None
    Comments: Optional[str] = None

class SiteDetail(BaseModel):
    """Full site detail with all related records."""
    site: SiteRead
    access: list[AccessRead] = []
    recs: list[RecRead] = []
    test_results: list[TestResultRead] = []
    qams: list[QAMSRead] = []


# ── Create models (write) ─────────────────────────────────────
class SiteCreate(BaseModel):
    SiteID: str = Field(..., max_length=20)
    SiteName: Optional[str] = Field(None, max_length=200)
    lonNAD83IDTM: Optional[float] = None
    latNAD83IDTM: Optional[float] = None
    PLSSp: Optional[str] = Field(None, max_length=200)
    Notes: Optional[str] = Field(None, max_length=2000)
    CreatedBy: Optional[str] = Field(None, max_length=50)
    StatusID: Optional[int] = None  # will create StatusLink
    LinkRecID: Optional[str] = None  # auto-create RecLink to this RecID (e.g. temp audit doc)

class RecUpdate(BaseModel):
    """Fields that can be updated on an existing Rec."""
    RecTypeID: Optional[int] = None
    RecLink: Optional[str] = Field(None, max_length=500)
    RecNumber: Optional[str] = Field(None, max_length=50)
    Title: Optional[str] = Field(None, max_length=300)
    RecDate: Optional[date] = None
    Notes: Optional[str] = Field(None, max_length=2000)

class RecLinkCreate(BaseModel):
    """Link an existing Rec to an existing Site."""
    RecID: str = Field(..., max_length=50)
    SiteID: str = Field(..., max_length=20)

class RecCreate(BaseModel):
    RecID: str = Field(..., max_length=50)
    SiteID: str = Field(..., max_length=20)  # for RecLink
    RecTypeID: int
    RecLink: Optional[str] = Field(None, max_length=500)
    RecNumber: Optional[str] = Field(None, max_length=50)
    Title: Optional[str] = Field(None, max_length=300)
    RecDate: Optional[date] = None
    Notes: Optional[str] = Field(None, max_length=2000)
    CreatedBy: Optional[str] = Field(None, max_length=50)

class TestResultCreate(BaseModel):
    SiteID: str = Field(..., max_length=20)
    TestTypeID: int
    RecID: Optional[str] = None  # for TestResultLink
    CommodityID: Optional[int] = None
    MaterialTypeID: Optional[int] = None
    TestValue: Optional[str] = Field(None, max_length=100)
    TestDate: Optional[date] = None
    LabName: Optional[str] = Field(None, max_length=100)
    SampleID: Optional[str] = Field(None, max_length=50)
    Notes: Optional[str] = None
    CreatedBy: Optional[str] = Field(None, max_length=50)

class QAMSCreate(BaseModel):
    RecID: str = Field(..., max_length=50)
    SiteID: str = Field(..., max_length=20)
    QualExpDate: Optional[date] = None
    LastRenewalDate: Optional[date] = None
    ApprovedFor: Optional[str] = Field(None, max_length=500)
    ConditionalUses: Optional[str] = Field(None, max_length=500)
    CertLetterRecID: Optional[str] = Field(None, max_length=50)
    Notes: Optional[str] = None
    CreatedBy: Optional[str] = Field(None, max_length=50)


# ── Batch commit ──────────────────────────────────────────────
class StagedRecord(BaseModel):
    """A single staged record from the frontend queue."""
    id: str
    table: str  # Sites, Rec, TestResult, QAMS
    fields: dict
    depends: Optional[list[str]] = None

class CommitRequest(BaseModel):
    records: list[StagedRecord]

class CommitResult(BaseModel):
    success: bool
    committed: int = 0
    errors: list[str] = []
    details: list[dict] = []
