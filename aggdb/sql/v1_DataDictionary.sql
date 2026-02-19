/*
  RP-315 DATA DICTIONARY - Field Traceability: ITD Spec -> Schema
  Every field from 2026.01.22.DRAFT.DatabaseFields 4.xlsx mapped below.

  RECONCILIATION: 81 spec fields
    Attribute fields (rows 2-50): 49 -> Source table columns
    Test types (rows 54-83):      30 -> LU_TestType rows
    Section header (row 53):       1 -> N/A
    Blank rows (51-52):            2 -> N/A
    Total mapped:                 81

  SCHEMA OBJECTS: 8
    Feature class: Source (49 spec fields + PK + computed + 4 audit = 55 cols)
    Related table: TestResult (11 data cols + PK + 4 audit)
    Lookups: LU_Commodity(17), LU_Owner(9), LU_SourceStatus(6),
             LU_AccessType(6), LU_AccuracyLevel(6), LU_TestType(30)
*/

-- TABLE: dbo.Source (ESRI Feature Class - Point)
-- Row | Spec Field                        | Column                          | Type              | Domain
--   2 | Source No                         | SourceNo                        | VARCHAR(20) NN UQ |
--   3 | Source Name                       | SourceName                      | VARCHAR(150)      |
--   4 | Commodity                         | CommodityID                     | INT FK            | LU_Commodity (17)
--   5 | Owner                             | OwnerID                         | INT FK            | LU_Owner (9)
--   6 | Source Status                     | SourceStatusID                  | INT FK            | LU_SourceStatus (6)
--   7 | Source Latitude                   | SourceLatitude                  | DECIMAL(10,8)     |
--   8 | Source Longitude                  | SourceLongitude                 | DECIMAL(11,8)     |
--   9 | Physical Source Address            | PhysicalSourceAddress           | VARCHAR(500)      |
--  10 | PLSS                              | PLSS                            | VARCHAR(200)      |
--  11 | Plat                              | PlatLink                        | VARCHAR(500)      |
--  12 | Arch Clearance                    | ArchClearanceLink               | VARCHAR(500)      |
--  13 | Reclamation Plan                  | ReclamationPlanLink             | VARCHAR(500)      |
--  14 | Permit                            | PermitLink                      | VARCHAR(500)      |
--  15 | Deed                              | DeedLink                        | VARCHAR(500)      |
--  16 | Parcel Num                        | ParcelNum                       | VARCHAR(50)       |
--  17 | SWIPP                             | SWIPPLink                       | VARCHAR(500)      |
--  18 | Relinquishment Date               | RelinquishmentDate              | DATE              |
--  19 | Area Acres                        | AreaAcres                       | DECIMAL(10,2)     |
--  20 | Plat Acres                        | PlatAcres                       | DECIMAL(10,2)     |
--  21 | DifferenceBtwAreaAndPlat           | DifferenceBtwAreaAndPlat        | COMPUTED          |
--  22 | Photos                            | PhotosLink                      | VARCHAR(500)      |
--  23 | Imagery                           | ImageryLink                     | VARCHAR(500)      |
--  24 | Accuracy Confidence               | AccuracyConfidenceID            | INT FK            | LU_AccuracyLevel (6)
--  25 | Avoidance Area                    | AvoidanceArea                   | VARCHAR(500)      |
--  26 | Avoidance Area Link               | AvoidanceAreaLink               | VARCHAR(500)      |
--  27 | Contact Name                      | ContactName                     | VARCHAR(100)      |
--  28 | Company Name                      | CompanyName                     | VARCHAR(150)      |
--  29 | Mailing Address                   | MailingAddress                  | VARCHAR(200)      |
--  30 | City, State, Zip                  | CityStateZip                    | VARCHAR(100)      |
--  31 | Email Address                     | EmailAddress                    | VARCHAR(150)      |
--  32 | Work Phone                        | WorkPhone                       | VARCHAR(20)       |
--  33 | Cell Phone                        | CellPhone                       | VARCHAR(20)       |
--  34 | QAMS: Qualification Expiration    | QAMSQualificationExpDate        | DATE              |
--  35 | QAMS: Last Renewal Date           | QAMSLastRenewalDate             | DATE              |
--  36 | QAMS: Source Approved For          | QAMSSourceApprovedFor           | VARCHAR(500)      |
--  37 | QAMS: Conditional Uses            | QAMSConditionalUses             | VARCHAR(1000)     |
--  38 | QAMS: Certification Letter Link   | QAMSCertificationLetterLink     | VARCHAR(500)      |
--  39 | Access Road Name                  | AccessRoadName                  | VARCHAR(150)      |
--  40 | Staging Name                      | StagingName                     | VARCHAR(150)      |
--  41 | Staging No.                       | StagingNo                       | VARCHAR(20)       |
--  42 | Documents re: Access              | DocumentsReAccess               | VARCHAR(500)      |
--  43 | Access Type                       | AccessTypeID                    | INT FK            | LU_AccessType (6)
--  44 | Access Ownership                  | AccessOwnership                 | VARCHAR(150)      |
--  45 | Access Document Link              | AccessDocumentLink              | VARCHAR(500)      |
--  46 | Access Document Number            | AccessDocumentNumber            | VARCHAR(50)       |
--  47 | Access Link                       | AccessLink                      | VARCHAR(500)      |
--  48 | Access Comments                   | AccessComments                  | VARCHAR(1000)     |
--  49 | Field Verified                    | FieldVerified                   | DATE              |
--  50 | IR142 Link                        | IR142Link                       | VARCHAR(500)      |

-- TABLE: dbo.TestResult (30 test types normalized into rows)
-- Column         | Type           | Notes
-- TestResultID   | INT PK         | Auto-increment
-- SourceID       | INT FK         | -> Source.SourceID
-- TestTypeID     | INT FK         | -> LU_TestType.TestTypeID (30 types)
-- TestDate       | DATE           | When test was performed
-- TestValue      | DECIMAL(18,6)  | Measured numeric result
-- SpecLimit      | DECIMAL(18,6)  | Specification threshold
-- SpecOperator   | VARCHAR(5)     | max, min, range
-- PassFail       | VARCHAR(4)     | Pass or Fail
-- LabName        | VARCHAR(150)   | Testing laboratory
-- SampleID       | VARCHAR(50)    | Lab sample identifier
-- Notes          | VARCHAR(2000)  | Explanation field per spec row 53
