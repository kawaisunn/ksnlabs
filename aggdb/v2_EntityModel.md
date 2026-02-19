# RP-315 AggDB — v2 Entity/Contact Model

**Date**: 2026-02-19
**Status**: Active development — evolved from Party model during interactive design session

---

## Design Decisions

### Why "Entity" instead of "Party"
Entity is the generic term for anything contactable — a person, a business, an agency.
The same Entity table serves both because the name structure (NameOne/Two/Three) flexes
for "Dr / John / Smith" and "Idaho / Sand & / Gravel" equally.

### Why split EntityType and EntityRole
EntityType describes **what the entity IS**: Person, LLC, Inc., Co., Corp., Agency, etc.
EntityRole describes **what the entity DOES at a site**: Owner, Operator, Lessee, etc.

These are orthogonal. A Person can be an Owner. An LLC can be an Operator.
Combining them in one lookup made it impossible to query "show me all businesses"
separately from "show me all owners."

### Why EntityLink needs SiteID
Without SiteID, you can say "John Smith is an owner" but not "John Smith is the
owner of Br0002c." The junction must carry the site reference.

### Why EntityAddress bundles everything
A contact card has address + email + web + phone + fax. One record = one snapshot
of how to reach someone. The junction (EntityLink) connects an entity to a contact
card at a site with a role and temporal validity.

---

## Table Structures

### Entity
```
EntityID        INT IDENTITY PK
EntityTypeID    INT FK → LU_EntityType
Prefix          VARCHAR(20)       -- Dr, Mr, Mrs, Sir
NameOne         VARCHAR(150)      -- FirstName or CompanyPart1
NameTwo         VARCHAR(150)      -- MiddleName or CompanyPart2
NameThree       VARCHAR(150)      -- LastName or CompanyPart3
SuffixOne       VARCHAR(50)       -- Jr, Sr, III
SuffixTwo       VARCHAR(50)       -- PE, PhD
SuffixThree     VARCHAR(50)       -- RG, CEG
Alias           VARCHAR(200)      -- DBA, common name
DisplayName     VARCHAR(300)      -- Computed or manual for dropdowns
IsActive        BIT DEFAULT 1
CreatedDate     DATETIME2
CreatedBy       VARCHAR(50)
ModifiedDate    DATETIME2
ModifiedBy      VARCHAR(50)
```

### EntityAddress
```
AddressID       INT IDENTITY PK
LineOne         VARCHAR(200)      -- Street address line 1
LineTwo         VARCHAR(200)      -- Suite, PO Box, etc.
City            VARCHAR(100)
State           VARCHAR(50)
ZipCode         VARCHAR(20)
EmailOne        VARCHAR(200)
EmailTwo        VARCHAR(200)
WebOne          VARCHAR(500)      -- Website URL
WebTwo          VARCHAR(500)
PhoneOne        VARCHAR(20)       -- Work phone
PhoneTwo        VARCHAR(20)       -- Cell phone
PhoneFax        VARCHAR(20)
CreatedDate     DATETIME2
CreatedBy       VARCHAR(50)
ModifiedDate    DATETIME2
ModifiedBy      VARCHAR(50)
```

### EntityLink (Junction)
```
EntityLinkID    INT IDENTITY PK
SiteID          INT FK → Site
EntityID        INT FK → Entity
AddressID       INT FK → EntityAddress
RoleID          INT FK → LU_EntityRole
EffectiveDate   DATE
EndDate         DATE              -- NULL = current
IsPrimary       BIT DEFAULT 0
Notes           VARCHAR(1000)
```

### LU_EntityType
```
EntityTypeID    INT IDENTITY PK
EntityTypeName  VARCHAR(50) UNIQUE
SortOrder       INT
```
Values: Person, Co., Inc., Ltd., LLC, LLP, Corp., Agency, Bureau, Trust, Partnership, Other

### LU_EntityRole
```
RoleID          INT IDENTITY PK
RoleName        VARCHAR(50) UNIQUE
SortOrder       INT
```
Values: Owner, Operator, Lessee, ITD Liaison, Lab, Contractor, Consultant, Permittee, Contact, Other

---

## Relationships

```
Entity     1 ──< many EntityLink   (one entity, many site roles)
EntityAddr 1 ──< many EntityLink   (one address, reused across links)
Site       1 ──< many EntityLink   (one site, many entities over time)
LU_EntityType 1 ──< many Entity    (Person, LLC, Inc., etc.)
LU_EntityRole 1 ──< many EntityLink (Owner, Operator, Lessee, etc.)
```

---

## ITD Spec Field Coverage (Rows 27-33)

| Spec Row | Spec Field      | → Entity Model                    |
|----------|-----------------|-----------------------------------|
| 27       | Contact Name    | Entity.Prefix/NameOne/Two/Three   |
| 28       | Company Name    | Entity.NameOne (Type=LLC/Inc/etc) |
| 29       | Mailing Address | EntityAddress.LineOne             |
| 30       | City,State,Zip  | EntityAddress.City/State/ZipCode  |
| 31       | Email Address   | EntityAddress.EmailOne            |
| 32       | Work Phone      | EntityAddress.PhoneOne            |
| 33       | Cell Phone      | EntityAddress.PhoneTwo            |
