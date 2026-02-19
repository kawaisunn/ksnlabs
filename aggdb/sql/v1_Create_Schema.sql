/*
============================================================================
  RP-315 Aggregate Materials Source Management Database
  Idaho Transportation Department / Idaho Geological Survey
  
  Schema Version:  1.0 (Presentation Draft)
  Date:            2026-02-19
  Platform:        SQL Server with ESRI ArcGIS Enterprise SDE
  Spec Source:     2026.01.22.DRAFT.DatabaseFields 4.xlsx (Sheet2, 81 fields)
  
  Design Notes:
  - Source table maps 1:1 to the ITD spec flat record and serves as the
    ESRI-registered feature class (point geometry added via ArcGIS).
  - TestResult normalizes the 30 test types into a single child table
    rather than 180+ columns (30 tests x 6 fields each).
  - Lookup tables enforce domain integrity for coded value fields.
  - All field names trace directly to the spec. Naming convention uses
    PascalCase for SQL Server / ESRI compatibility.
  - DifferenceBtwAreaAndPlat is a computed column (AreaAcres - PlatAcres).
  - Link fields retained as VARCHAR per spec; ESRI hyperlink-capable.
============================================================================
*/

USE [AggDB];
GO

-- ============================================================================
-- LOOKUP TABLES
-- ============================================================================

CREATE TABLE dbo.LU_Commodity (
    CommodityID     INT IDENTITY(1,1) PRIMARY KEY,
    CommodityName   VARCHAR(50) NOT NULL UNIQUE,
    SortOrder       INT NULL
);
GO

INSERT INTO dbo.LU_Commodity (CommodityName, SortOrder) VALUES
('Basalt',              1),
('Granite',             2),
('Dolomite_Limestone',  3),
('Slate_Shale',         4),
('Rhyolite',            5),
('Sand',                6),
('General Gravel',      7),
('General Aggregate',   8),
('Quartz',              9),
('General Stone',       10),
('Cinders',             11),
('Boulders',            12),
('RAP',                 13),
('RCA',                 14),
('Pumice',              15),
('Unknown',             16),
('Other',               17);
GO

CREATE TABLE dbo.LU_Owner (
    OwnerID     INT IDENTITY(1,1) PRIMARY KEY,
    OwnerName   VARCHAR(50) NOT NULL UNIQUE,
    SortOrder   INT NULL
);
GO

INSERT INTO dbo.LU_Owner (OwnerName, SortOrder) VALUES
('County',          1),
('USFS',            2),
('BLM - ITD',       3),
('ITD',             4),
('IDOL - ITD',      5),
('State Other',     6),
('BOR',             7),
('Fish Game',       8),
('Other',           9);
GO

CREATE TABLE dbo.LU_SourceStatus (
    SourceStatusID      INT IDENTITY(1,1) PRIMARY KEY,
    SourceStatusName    VARCHAR(50) NOT NULL UNIQUE,
    SortOrder           INT NULL
);
GO

INSERT INTO dbo.LU_SourceStatus (SourceStatusName, SortOrder) VALUES
('Active',                  1),
('Staging Area',            2),
('Depleted',                3),
('Retired_Relinquished',    4),
('QAMS',                    5),
('Other',                   6);
GO

CREATE TABLE dbo.LU_AccessType (
    AccessTypeID    INT IDENTITY(1,1) PRIMARY KEY,
    AccessTypeName  VARCHAR(50) NOT NULL UNIQUE,
    SortOrder       INT NULL
);
GO

-- Placeholder values; spec does not enumerate these
INSERT INTO dbo.LU_AccessType (AccessTypeName, SortOrder) VALUES
('Paved',       1),
('Gravel',      2),
('Dirt',        3),
('Trail',       4),
('None',        5),
('Other',       6);
GO

CREATE TABLE dbo.LU_AccuracyLevel (
    AccuracyLevelID     INT IDENTITY(1,1) PRIMARY KEY,
    AccuracyLevelName   VARCHAR(50) NOT NULL UNIQUE,
    SortOrder           INT NULL
);
GO

INSERT INTO dbo.LU_AccuracyLevel (AccuracyLevelName, SortOrder) VALUES
('Survey Grade',    1),
('Sub-meter GPS',   2),
('Recreational GPS',3),
('Map Derived',     4),
('Estimated',       5),
('Unknown',         6);
GO

CREATE TABLE dbo.LU_TestType (
    TestTypeID      INT IDENTITY(1,1) PRIMARY KEY,
    TestCode        VARCHAR(20)   NOT NULL UNIQUE,
    TestName        VARCHAR(200)  NOT NULL,
    TestStandard    VARCHAR(20)   NOT NULL,  -- Idaho, AASHTO, ASTM, CRD
    Description     VARCHAR(1000) NULL,
    SortOrder       INT NULL
);
GO

INSERT INTO dbo.LU_TestType (TestCode, TestName, TestStandard, Description, SortOrder) VALUES
-- Idaho Tests (5)
('IT15',    'Idaho Degradation',                                    'Idaho',    'Qualify or disqualify aggregate sources for use in Idaho transportation projects.', 1),
('IT116',   'Idaho Ethylene Glycol',                                'Idaho',    'Disintegration of Quarry Aggregates.', 2),
('IT13',    'Mortar-Making Properties of Fine Aggregate',           'Idaho',    'Determines whether a natural, unproven fine aggregate is suitable.', 3),
('IT8',     'R-value',                                              'Idaho',    'Determines resistance R-value and expansion pressure of compacted soils.', 4),
('IT144',   'Idaho Specific Gravity (Fine)',                        'Idaho',    'Determination of specific gravity and absorption of fine aggregate.', 5),
-- AASHTO Tests (19)
('T104F',   'Na Soundness (Fine)',                                  'AASHTO',   'Index of general aggregate quality - fine fraction.', 6),
('T104C',   'Na Soundness (Coarse)',                                'AASHTO',   'Index of general aggregate quality - coarse fraction.', 7),
('T303',    'Accelerated Detection Potentially Deleterious Expansion','AASHTO', 'Identifies potential for harmful expansion in mortar bars.', 8),
('TP110',   'Potential Alkali Reactivity of Aggregates (AMBT)',     'AASHTO',   'ASR evaluation via accelerated mortar bar test.', 9),
('T380',    'Miniature Concrete Prism Test (MCPT)',                 'AASHTO',   'Evaluate reactivity of an aggregate.', 10),
('TP142',   'Accelerated Concrete Cylinder Test (ACCT)',            'AASHTO',   'Accelerated determination of potentially deleterious expansion.', 11),
('T176',    'Sand Equivalent Test',                                 'AASHTO',   'Rapid field correlation test for relative proportions of fines.', 12),
('T21',     'Organic Impurities in Fine Aggregates',                'AASHTO',   'Assesses presence of potentially harmful organic compounds.', 13),
('T71',     'Effect of Organic Impurities on Strength',             'AASHTO',   'Assesses suitability of fine aggregate for concrete.', 14),
('T112',    'Clay Lumps and Friable Particles',                     'AASHTO',   'Determines percentage of clay lumps and friable particles.', 15),
('T113',    'Lightweight Particles in Aggregate',                   'AASHTO',   'Determines percentage of lightweight particles.', 16),
('T96',     'Los Angeles Wear',                                     'AASHTO',   'Evaluation of resistance of coarse aggregate to degradation by abrasion.', 17),
('T182',    'Coating and Stripping of Bitumen-Aggregate Mixtures',  'AASHTO',   'Coating and static immersion procedures.', 18),
('T84',     'Specific Gravity and Absorption of Fine Aggregate',    'AASHTO',   'Specific gravity for mix design calculations - fine.', 19),
('T85',     'Specific Gravity and Absorption of Coarse Aggregate',  'AASHTO',   'Specific gravity for mix design calculations - coarse.', 20),
('T19',     'Bulk Density (Unit Weight) and Voids',                 'AASHTO',   'Evaluating properties of aggregate for proportioning concrete mixtures.', 21),
('T89',     'Atterberg Limits: Liquid Limit',                       'AASHTO',   'Water content thresholds defining soil behavior.', 22),
('T90',     'Atterberg Limits: Plastic Limit/Index',                'AASHTO',   'Water content thresholds defining soil behavior.', 23),
('T330',    'Qualitative Detection of Harmful Clays (Methylene Blue)','AASHTO', 'Identifies presence of harmful clays of the smectite group.', 24),
-- ASTM Tests (5)
('C1293',   'Length Change of Concrete Due to ASR',                 'ASTM',     'Evaluates potential of aggregate or combination for ASR.', 25),
('C535',    'Resistance to Degradation of Large-Size Aggregate',    'ASTM',     'Indicator of relative quality of coarse aggregate.', 26),
('C295',    'Petrographic Examination of Aggregates',               'ASTM',     'Determine physical and chemical characteristics.', 27),
('C1260',   'Potential Alkali Reactivity (Mortar-Bar)',             'ASTM',     'Detecting potential of aggregate for deleterious ASR expansion.', 28),
('C1567',   'Potential ASR with Cementitious Materials (Mortar-Bar)','ASTM',    'Evaluates ability of pozzolans and slag to prevent ASR.', 29),
-- CRD Tests (1)
('CRD-C662','Potential ASR with Cementitious Materials (Concrete Prism)','CRD', 'Permits detection within 30 days of potential for deleterious ASR.', 30);
GO

-- ============================================================================
-- SOURCE TABLE  (ESRI Feature Class - Point Geometry)
-- ============================================================================

CREATE TABLE dbo.Source (
    SourceID                    INT IDENTITY(1,1) PRIMARY KEY,
    SourceNo                    VARCHAR(20)   NOT NULL UNIQUE,
    SourceName                  VARCHAR(150)  NULL,
    CommodityID                 INT NULL REFERENCES dbo.LU_Commodity(CommodityID),
    OwnerID                     INT NULL REFERENCES dbo.LU_Owner(OwnerID),
    SourceStatusID              INT NULL REFERENCES dbo.LU_SourceStatus(SourceStatusID),
    SourceLatitude              DECIMAL(10,8) NULL,
    SourceLongitude             DECIMAL(11,8) NULL,
    PhysicalSourceAddress       VARCHAR(500)  NULL,
    PLSS                        VARCHAR(200)  NULL,
    PlatLink                    VARCHAR(500)  NULL,
    ArchClearanceLink           VARCHAR(500)  NULL,
    ReclamationPlanLink         VARCHAR(500)  NULL,
    PermitLink                  VARCHAR(500)  NULL,
    DeedLink                    VARCHAR(500)  NULL,
    SWIPPLink                   VARCHAR(500)  NULL,
    PhotosLink                  VARCHAR(500)  NULL,
    ImageryLink                 VARCHAR(500)  NULL,
    AvoidanceAreaLink           VARCHAR(500)  NULL,
    QAMSCertificationLetterLink VARCHAR(500)  NULL,
    AccessDocumentLink          VARCHAR(500)  NULL,
    AccessLink                  VARCHAR(500)  NULL,
    IR142Link                   VARCHAR(500)  NULL,
    ParcelNum                   VARCHAR(50)   NULL,
    RelinquishmentDate          DATE          NULL,
    AreaAcres                   DECIMAL(10,2) NULL,
    PlatAcres                   DECIMAL(10,2) NULL,
    DifferenceBtwAreaAndPlat    AS (AreaAcres - PlatAcres),
    AccuracyConfidenceID        INT NULL REFERENCES dbo.LU_AccuracyLevel(AccuracyLevelID),
    AvoidanceArea               VARCHAR(500)  NULL,
    FieldVerified               DATE          NULL,
    ContactName                 VARCHAR(100)  NULL,
    CompanyName                 VARCHAR(150)  NULL,
    MailingAddress              VARCHAR(200)  NULL,
    CityStateZip                VARCHAR(100)  NULL,
    EmailAddress                VARCHAR(150)  NULL,
    WorkPhone                   VARCHAR(20)   NULL,
    CellPhone                   VARCHAR(20)   NULL,
    QAMSQualificationExpDate    DATE          NULL,
    QAMSLastRenewalDate         DATE          NULL,
    QAMSSourceApprovedFor       VARCHAR(500)  NULL,
    QAMSConditionalUses         VARCHAR(1000) NULL,
    AccessRoadName              VARCHAR(150)  NULL,
    StagingName                 VARCHAR(150)  NULL,
    StagingNo                   VARCHAR(20)   NULL,
    DocumentsReAccess           VARCHAR(500)  NULL,
    AccessTypeID                INT NULL REFERENCES dbo.LU_AccessType(AccessTypeID),
    AccessOwnership             VARCHAR(150)  NULL,
    AccessDocumentNumber        VARCHAR(50)   NULL,
    AccessComments              VARCHAR(1000) NULL,
    CreatedDate                 DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CreatedBy                   VARCHAR(50)  NOT NULL DEFAULT SYSTEM_USER,
    ModifiedDate                DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    ModifiedBy                  VARCHAR(50)  NOT NULL DEFAULT SYSTEM_USER
);
GO

-- ============================================================================
-- TEST RESULT TABLE
-- ============================================================================

CREATE TABLE dbo.TestResult (
    TestResultID    INT IDENTITY(1,1) PRIMARY KEY,
    SourceID        INT NOT NULL REFERENCES dbo.Source(SourceID),
    TestTypeID      INT NOT NULL REFERENCES dbo.LU_TestType(TestTypeID),
    TestDate        DATE          NULL,
    TestValue       DECIMAL(18,6) NULL,
    SpecLimit       DECIMAL(18,6) NULL,
    SpecOperator    VARCHAR(5)    NULL,
    PassFail        VARCHAR(4)    NULL CHECK (PassFail IN ('Pass','Fail')),
    LabName         VARCHAR(150)  NULL,
    SampleID        VARCHAR(50)   NULL,
    Notes           VARCHAR(2000) NULL,
    CreatedDate     DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CreatedBy       VARCHAR(50)  NOT NULL DEFAULT SYSTEM_USER,
    ModifiedDate    DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    ModifiedBy      VARCHAR(50)  NOT NULL DEFAULT SYSTEM_USER
);
GO

CREATE INDEX IX_TestResult_Source_Type ON dbo.TestResult (SourceID, TestTypeID, TestDate);
CREATE INDEX IX_Source_LatLon ON dbo.Source (SourceLatitude, SourceLongitude) WHERE SourceLatitude IS NOT NULL;
CREATE INDEX IX_Source_Commodity ON dbo.Source (CommodityID);
CREATE INDEX IX_Source_Owner ON dbo.Source (OwnerID);
CREATE INDEX IX_Source_Status ON dbo.Source (SourceStatusID);
CREATE INDEX IX_Source_AccessType ON dbo.Source (AccessTypeID);
CREATE INDEX IX_Source_Accuracy ON dbo.Source (AccuracyConfidenceID);
GO
