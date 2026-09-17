# Business Overview — Golfler / ClubCaddie Platform

**Source**: Live codebase scan — `stable-codebase\` (2026-06-10)

---

## Business Context Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     CLUBCADDIE / GOLFLER PLATFORM                       │
│                   Multi-Tenant Golf Course Management SaaS              │
├──────────────────────────────┬──────────────────────────────────────────┤
│      STAFF OPERATIONS        │         CUSTOMER / MEMBER OPERATIONS     │
│                              │                                          │
│  • POS Transactions          │  • Online Tee Time Booking              │
│  • Tee Sheet Management      │  • Membership Self-Service              │
│  • Inventory / Products      │  • Online Event Registration            │
│  • Event Management          │  • Voucher Purchase / Redemption        │
│  • Membership Administration │  • Mobile App (iOS, Android)            │
│  • Financial Reporting       │  • Customer Portal (web)                │
│  • Staff Management          │  • iFrame Booking Widgets               │
│                              │                                          │
│  TOOLS: WPF PosApp           │  TOOLS: cc_membership_portal            │
│         CCOnline (Angular)   │           cc_api_manager (iFrames)      │
│         Admin Portal         │           cc_ios / cc_android           │
└──────────────────────────────┴──────────────────────────────────────────┘
                               │
                ┌──────────────▼──────────────┐
                │   golfler_asp_2 Backend      │
                │   (PosApi + GolferWebAPI +   │
                │    GolflerF SQL Server)      │
                └─────────────────────────────┘
```

---

## Business Description

The Golfler / ClubCaddie platform is a multi-tenant SaaS golf course management system used by golf and country clubs to manage all aspects of their operations. Each course (tenant) operates in complete isolation via `CourseId`-scoped data access — there is no row-level security at the database level; multi-tenancy is enforced entirely in application code.

The platform has two distinct audiences:
- **Staff** (course employees): POS transactions, tee sheet scheduling, inventory, events, memberships, CRM, reporting
- **Customers/Members** (golfers): Online booking, membership self-service, event registration, vouchers, mobile apps

---

## Business Transactions

The following business transactions are implemented across the platform:

### Tee Time & Reservation Management
- Tee time booking (staff via POS/CCOnline; customer via portal/mobile/iFrame)
- Lottery/ballot tee sheet allocation
- Tee sheet management (blocks, holds, walkins)
- Tee time cancellation, modification, history

### Point of Sale (POS)
- Order creation — green fees, F&B, pro shop, activities
- Payment processing (multiple gateways: CardConnect, Clover, AuthorizeNet, Spreedly, Braintree, Stripe, BluePay, FirstPay, BasysCard)
- Cash payout / cash management
- Receipt printing (thermal via node-thermal-printer; PDF via IronPdf)
- On-demand (tablet/QR) ordering

### Membership Management
- Membership plan administration and pricing
- Member invoicing and billing (monthly billing, date-specific billing via Hangfire jobs)
- Member ledger and payment history
- Membership auto-pay setup
- Membership application and registration
- Member minimum spend rules, class types, group rules

### Inventory / Products
- Product catalog and pricing
- Tax configuration including tax-inclusive pricing
- Purchase orders and invoices
- Inventory adjustment

### Event Management
- Tournament and event creation (golf leagues, outings, banquets, activities)
- Online event registration (via cc_api_manager iFrames)
- Event payment collection
- Player/golfer management for events

### Customer Relationship Management (CRM)
- Customer profile management
- Credit voucher issuance and redemption
- Punch card management
- Promo code management
- Customer wallet (stored payment methods)
- Email campaigns (HubSpot, CampaignMonitor, CriticalImpact)
- Bulletin board

### Financial Reporting
- Chart of accounts (with GL extensions for Great Plains, Oracle, QuickBooks)
- Journal entry management
- Reconciliation reports (CardConnect, Clover payment reports)
- Member financial statements

### Online Self-Service (Customer)
- Tee time booking (via cc_membership_portal and cc_api_manager iFrames)
- Membership viewing and management
- Event registration and payment
- Voucher purchase and checkout
- Member directory

### Platform Integrations
- Third-party aggregators: Forefront, ORCA, LightSpeed, RedWater, X-Golf, XGolf, PlayersFirst
- Accounting: QuickBooks Online, Great Plains, Oracle
- Rangefinder integration
- Cross-club interface (CCInterface — multi-club management)
- MCO (Management Company Organization) operations

---

## Business Dictionary

| Term | Meaning |
|---|---|
| **CourseId** | Tenant identifier — every DB query must include it; omitting leaks data across clubs |
| **GF_** prefix | All database tables have this prefix (e.g. GF_Order, GF_Customer, GF_Settings) |
| **PosApi** | Staff-facing Web API — used by WPF PosApp, Angular CCOnline, Golfler Admin |
| **GolferWebAPI** | Customer/mobile-facing Web API — used by PHP portals, iOS, Android |
| **GolflerShared** | Shared business logic compiled into all .NET projects — payment, booking, utilities |
| **GolflerDataModel** | EF6 database-first EDMX — single DbContext (`GolflerDataModelEntities`) for all 431 tables |
| **CCOnline** | The Angular web staff management interface (`sgs-cts-angular`) |
| **PosApp** | The WPF desktop staff POS terminal (`golfler_pos_2`) |
| **iFrame** | Booking/membership/event widgets embedded in club websites via `cc_api_manager` |
| **WebSetting** | Key-value settings table (`GF_Settings`) with constants in `CommonProperties.cs` |
| **Hangfire** | Background job framework hosted in PosApi — runs membership billing jobs |
| **GolflerF** | The production SQL Server database name |
| **Tee Sheet** | The scheduling grid showing tee time availability and bookings |
| **OnDemand** | Tablet/QR code based ordering (food, beverage, products at the course) |
| **MCO** | Management Company Organization — multi-club management interface |
| **CCAZUREDEV2** | Primary dev/staging Azure environment name (seen in Jenkins deploy scripts) |

---

## Component Level Business Descriptions

### golfler_asp_2 (Backend)
- **Purpose**: The entire business logic of the platform. All APIs, all data access, all business rules.
- **Responsibilities**: POS operations, member management, tee sheet, events, inventory, reporting, payments, integrations, background billing, admin portal

### golfler_pos_2 (WPF POS App)
- **Purpose**: Staff-facing point-of-sale terminal installed on Windows machines at the course
- **Responsibilities**: Taking orders, processing payments, managing tee times, checking in golfers, events, membership operations at the counter. Uses 100+ ViewModels and 100+ dialog windows.

### sgs-cts-angular (CCOnline Web App)
- **Purpose**: Web-based staff management interface replacing/complementing the WPF app for browser-based usage
- **Responsibilities**: Same domain as PosApp but web-based. Notably includes OpenAI integration and Electron packaging capability (can run as desktop app).

### cc_api_manager (iFrame Booking Widgets)
- **Purpose**: Provides embeddable HTML iFrames that club websites use to offer online booking to customers
- **Responsibilities**: Tee time booking iFrame, event registration, membership purchase, voucher purchase, promo code entry, online payment. All data via GolferWebAPI.

### cc_membership_portal (Customer Portal)
- **Purpose**: Customer-facing self-service web portal for existing members
- **Responsibilities**: Member login, tee sheet viewing/booking, event registration, voucher management, member directory, bulletin board, membership usage tracking. Three generations of controllers coexist (`controllers/`, `controllers_1/`, `controllers_old/`).
