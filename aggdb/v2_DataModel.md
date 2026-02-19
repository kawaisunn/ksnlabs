# RP-315 AggDB — v2 Data Model Reorganization
## Complete Field-to-Entity Mapping (All 81 ITD Spec Fields)

**Date**: 2026-02-19
**Constraint**: All 81 ITD spec fields. Nothing invented. Proper normalization.
**Platform**: SQL Server + ESRI ArcGIS Enterprise SDE

> **EVOLUTION NOTE (2026-02-19 late session)**: The Party model described below
> was refactored into an Entity model during interactive table building. See
> `aggdb/v2_EntityModel.md` for the current contact/entity structure:
> Entity, EntityAddress, EntityLink, LU_EntityType, LU_EntityRole.
> The 81-field mapping and all other tables remain as documented here.

---

## NAMING DECISIONS

The word **"Source"** is banned from all table and field names. In aggregate
materials, "source" is ambiguous — it could mean a gravel pit, a lab, a
technical manual, a water fountain. Every table and field gets a name that
no one from any of the six districts will confuse.

| ITD Spec Term         | Our Term             | Why                                        |
|-----------------------|----------------------|--------------------------------------------|
| Source No             | → SiteName record    | It's an identifier, one of several per site |
| Source Name           | → SiteName record    | It's a common name / alias                  |
| Source Status         | → OperationalStatus  | Describes whether site is Active/Depleted/etc |
| Source Latitude       | → Latitude           | It's the site's coordinate                  |
| Source Longitude      | → Longitude          | It's the site's coordinate                  |
| Physical Source Addr  | → PhysicalAddress    | Location description of the site            |
| Contact Name          | → Entity (Person)    | People are entities, not flat fields        |
| Company Name          | → Entity (Business)  | Companies are entities, not flat fields     |
| All doc links         | → Document records   | Each link is a document with type & metadata|
| Photos/Imagery        | → Document records   | Images are a type of document               |
| QAMS fields           | → Certification      | QAMS is a document with certification data  |
| Avoidance Area        | → Polygon record     | It's a polygon spatial feature              |

---

## TABLE INVENTORY

### Core + Spatial Tables
| # | Table            | Purpose                                              |
|---|------------------|------------------------------------------------------|
| 1 | Site             | Primary entity — the aggregate material location     |
| 2 | SiteName         | Identifiers, common names, aliases (ITD no, IGS no)  |
| 3 | Entity           | Any contactable party (person or business)           |
| 4 | EntityAddress    | Contact card: address, email, web, phone, fax        |
| 5 | EntityLink       | Junction: who plays what role at which site, when    |
| 6 | Document         | All documents, photos, imagery, QAMS certs           |
| 7 | Certification    | QAMS-specific extension of Document                  |
| 8 | TestResult       | Lab test results — attribute of a test report doc    |
| 9 | Access           | Physical access to the site (roads, staging)         |
| 10| Polygon          | Polygon features (avoidance areas, plat boundaries)  |
| 11| SpatialOther     | Placeholder for future spatial data needs            |

### Lookup Tables
| # | Table               | Values                                            |
|---|---------------------|---------------------------------------------------|
| 1 | LU_Commodity        | Basalt, Granite, ... (17 from spec)               |
| 2 | LU_OwnerType        | County, USFS, BLM-ITD, ... (9 from spec)         |
| 3 | LU_OperationalStatus| Active, Staging, Depleted, ... (6 from spec)      |
| 4 | LU_AccessType       | Road surface/type classifications                 |
| 5 | LU_AccuracyLevel    | Survey Grade → Estimated → Unknown                |
| 6 | LU_TestType         | 30 test standards (5 ID, 19 AASHTO, 5 ASTM, 1 CRD)|
| 7 | LU_EntityType       | Person, Co., Inc., Ltd., LLC, LLP, Corp., Agency...|
| 8 | LU_EntityRole       | Owner, Operator, Lessee, ITD Liaison, Lab...      |
| 9 | LU_NameType         | ITD_Number, IGS_Number, CommonName, Alias, Legal  |
| 10| LU_DocType          | Plat, Permit, Deed, Photo, QAMS, TestReport, ... |
| 11| LU_PolygonType      | AvoidanceArea, PlatBoundary, PropertyBoundary     |
| 12| LU_PLSSPolygon      | Placeholder — PLSS polygon handling TBD           |

---

## FIELD-BY-FIELD MAPPING (ALL 81 SPEC FIELDS)

| # | Spec Field (Row)                  | → v2 Table.Field                              |
|---|-----------------------------------|-----------------------------------------------|
| 1 | Source No (2)                     | SiteName (Type=ITD_Number)                    |
| 2 | Source Name (3)                   | SiteName (Type=CommonName)                    |
| 3 | Commodity (4)                     | Site.CommodityID                              |
| 4 | Owner (5)                         | Site.OwnerTypeID                              |
| 5 | Source Status (6)                 | Site.OperationalStatusID                      |
| 6 | Source Latitude (7)               | Site.Latitude                                 |
| 7 | Source Longitude (8)              | Site.Longitude                                |
| 8 | Physical Source Address (9)       | Site.PhysicalAddress                          |
| 9 | PLSS (10)                         | Site.PLSS                                     |
| 10| Plat (11)                         | Document (DocType=Plat)                       |
| 11| Arch Clearance (12)               | Document (DocType=ArchClearance)              |
| 12| Reclamation Plan (13)             | Document (DocType=ReclamationPlan)            |
| 13| Permit (14)                       | Document (DocType=Permit)                     |
| 14| Deed (15)                         | Document (DocType=Deed)                       |
| 15| Parcel Num (16)                   | Site.ParcelNum                                |
| 16| SWIPP (17)                        | Document (DocType=SWIPP)                      |
| 17| Relinquishment Date (18)          | Site.RelinquishmentDate                       |
| 18| Area Acres (19)                   | Site.AreaAcres                                |
| 19| Plat Acres (20)                   | Site.PlatAcres                                |
| 20| DifferenceBtwAreaAndPlat (21)     | Site (computed column)                        |
| 21| Photos (22)                       | Document (DocType=Photo)                      |
| 22| Imagery (23)                      | Document (DocType=Imagery)                    |
| 23| Accuracy Confidence (24)          | Site.AccuracyLevelID                          |
| 24| Avoidance Area (25)               | Polygon (PolygonType=AvoidanceArea)           |
| 25| Avoidance Area Link (26)          | Document (DocType=AvoidanceAreaDoc)           |
| 26| Contact Name (27)                 | Entity (Prefix/NameOne/Two/Three/Suffix/Cred) |
| 27| Company Name (28)                 | Entity (NameOne=company, Type=LLC/Inc/etc)    |
| 28| Mailing Address (29)              | EntityAddress.LineOne                         |
| 29| City, State, Zip (30)             | EntityAddress.City + State + ZipCode          |
| 30| Email Address (31)                | EntityAddress.EmailOne                        |
| 31| Work Phone (32)                   | EntityAddress.PhoneOne                        |
| 32| Cell Phone (33)                   | EntityAddress.PhoneTwo                        |
| 33| QAMS Qual Exp Date (34)           | Certification.ExpirationDate                  |
| 34| QAMS Last Renewal (35)            | Certification.LastRenewalDate                 |
| 35| QAMS Approved For (36)            | Certification.ApprovedFor                     |
| 36| QAMS Conditional Uses (37)        | Certification.ConditionalUses                 |
| 37| QAMS Cert Letter Link (38)        | Document (DocType=QAMSCertification)          |
| 38| Access Road Name (39)             | Access.RoadName                               |
| 39| Staging Name (40)                 | Access.StagingName                            |
| 40| Staging No (41)                   | Access.StagingNo                              |
| 41| Documents re: Access (42)         | Document (DocType=AccessDocument)             |
| 42| Access Type (43)                  | Access.AccessTypeID                           |
| 43| Access Ownership (44)             | Access.OwnershipTypeID                        |
| 44| Access Document Link (45)         | Document (DocType=AccessDocument)             |
| 45| Access Document Number (46)       | Document.DocNumber                            |
| 46| Access Link (47)                  | Document (DocType=AccessEasement)             |
| 47| Access Comments (48)              | Access.Comments                               |
| 48| Field Verified (49)               | Site.FieldVerified                            |
| 49| IR142 Link (50)                   | Document (DocType=IR142)                      |
| 50-79| 30 Test Types (54-83)          | TestResult → LU_TestType (30 rows)            |
| 80| (test explanation per spec)       | TestResult.Notes                              |
| 81| (test date per spec)              | TestResult.TestDate                           |

**All 81 fields accounted for. Zero invented. Zero lost.**

---

## KEY RELATIONSHIPS

```
Site ──< SiteName              (1 site : many names/identifiers)
Site ──< EntityLink >── Entity (many-to-many with role + dates)
         Entity ──< EntityAddress (1 entity : many contact cards over time)
         EntityLink carries: RoleID, SiteID, AddressID, EffectiveDate, EndDate
Site ──< Document              (1 site : many documents of various types)
         Document ──< TestResult    (1 test report : many test results)
         Document ──── Certification (1:1 for QAMS docs only)
Site ──< Access                (1 site : access records)
Site ──< Polygon               (1 site : many polygon features)
Site ──< SpatialOther          (1 site : placeholder spatial)
```
