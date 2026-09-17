# Component Inventory — Golfler / ClubCaddie Platform

**Source**: Live codebase scan — `stable-codebase\` (2026-06-10)

---

## Application Projects — golfler_asp_2 (ASP.NET Solution)

| Project | Framework | Purpose | Status |
|---|---|---|---|
| **PosApi** | ASP.NET Web API 2 / .NET 4.7.2 | Staff-facing REST API (orders, payments, inventory, reconciliation, memberships) | Active — primary |
| **GolferWebAPI** | ASP.NET Web API 2 / .NET 4.6.1 | Customer/mobile REST API (tee booking, memberships, aggregators) | Active — primary |
| **Golfler** | ASP.NET MVC 5 / .NET 4.7.2 | Admin web portal (course config, reporting, management) | Active |
| **CCU** | ASP.NET Core Web API 3.1 | Modern utility web interface | Active |
| **CCACHWebhook** | ASP.NET Core / .NET Core 3.1 | CardConnect ACH webhook receiver | Active |
| **CourseWebApi** | ASP.NET Web API 2 / .NET 4.6.1 | Tee sheet API — **DEPRECATED**, consolidating into PosApi | Deprecated |
| **GolflerDataModel** | Class Library / .NET 4.5.2 | EF6 Database-First EDMX, `GolflerDataModelEntities` DbContext, 431 GF_ tables | Active — shared |
| **GolflerShared** | Visual Studio Shared Project (.shproj) | Critical shared business logic: payment, booking, tee sheet, membership, utilities | Active — shared |
| **GolflerDB** | SQL Server Database Project (.sqlproj) | 431+ table DDL, stored procedures, views, migration scripts | Active |
| **PosApiUnitTest** | MSTest / .NET | Unit tests for PosApi — 2 stub files (MembershipControllerTest, PurchaseInvoiceControllerTest) | Minimal |
| **AzureUtilities** | Azure Functions / .NET Core | GL uploads, file storage, background jobs | Active |
| **HubSpotIntegration** | Class Library | HubSpot CRM sync | Active |
| **RangeExpress** | Azure Function | Range management automation | Active |
| **VoucherExpirationWindowsService** | Windows Service / .NET Framework | Monitors and expires vouchers | Active |
| **MaintenanceConsoleApp** | Console App / .NET Framework | Data migration and maintenance utilities | Active |
| **CCACHWebhook** | Console App | CardConnect ACH webhook receiver | Active |
| **POS** | WinForms | Legacy desktop POS client — minimal, largely superseded | Legacy |

---

## Application Project — golfler_pos_2 (WPF Desktop POS)

| Project | Framework | Purpose | Status |
|---|---|---|---|
| **POSApp** | WPF / .NET 4.7.1 | Main WPF application — UI, ViewModels (100+), dialogs (100+) | Active |
| **POSApp.Data** | Class Library | API contracts, data models, settings for PosApi calls | Active |
| **POSApp.Core** | Class Library | Shared business logic, utilities, services | Active |
| **POSUnitTest** | MSTest | Unit tests for POS — extent of coverage not examined | Present |

---

## Application Project — sgs-cts-angular (Angular Web App)

| Module | Purpose | Status |
|---|---|---|
| **register/** | POS register / checkout | Active |
| **teesheet/** | Tee sheet management | Active |
| **customers/** | Customer management (general, membership, payment, purchase history) | Active |
| **events/** | Event management | Active |
| **sales/** | Sales transactions | Active |
| **reports/** | 20+ report components | Active |
| **setting/** | Settings (general, inventory, users, tee times, tax, memberships, integrations) | Active |
| **dashboard/** | Main dashboard | Active |
| **ondemand/** | On-demand tablet ordering | Active |
| **memberships/** | Membership management | Active |
| **vouchers/** | Gift/credit vouchers | Active |
| **payment/** / **paymentV1/** | Payment methods (current + legacy) | Active + Legacy |
| **tips-management/** | Tips management | Active |
| **hubspot/** | HubSpot CRM integration | Active |
| **global-view/** | Global club dashboard | Active |
| **mco-dashboard/** | Multi-club overview | Active |
| **receipt-printer/** | Thermal printer receipt building | Active |

---

## Application Projects — cc_api_manager (PHP CodeIgniter)

| Controller | Purpose |
|---|---|
| `Webapi.php` | Central API proxy controller |
| `Manager.php` | Admin/manager controller |
| `Authorization.php` | Auth controller |
| `Banner.php` | iFrame banner |
| `Events.php` / `OnlineEvent.php` | Events booking iFrame |
| `Eventpayment.php` | Event payment flow |
| `Activities.php` / `MyActivities.php` | Activities booking + history |
| `MyTeeTimes.php` | Customer tee time history |
| `League.php` | League booking iFrame |
| `MembershipSaleStrategy1.php` / `MembershipSaleStrategy2.php` | Membership purchase flows |
| `Onlinepayment.php` | Online payment processing |
| `Posts.php` | Bulletin board |
| `Profile.php` | Customer profile |
| `PromoCode.php` | Promo codes |
| `Punchcards.php` | Punch cards |
| `Vouchers.php` / `Vouchers_checkout.php` | Voucher purchase/checkout |

---

## Application Projects — cc_membership_portal (PHP CodeIgniter)

| Controller | Purpose |
|---|---|
| `Auth.php` / `CustomerAuth.php` | Member + customer authentication |
| `McoAuth.php` / `XGolfAuth.php` | MCO + XGolf auth flows |
| `Member.php` | Main member portal controller |
| `Banner.php` / `BulletinBoard.php` | Portal homepage + bulletin board |
| `TeeSheet.php` / `TeeTimes.php` | Tee sheet + booking |
| `LotterySheet.php` | Lottery tee sheet |
| `Events.php` | Event listing/registration |
| `Reservation.php` | Reservations |
| `Vouchers.php` / `Vouchers_checkout.php` | Voucher management |
| `MembershipUsage.php` | Membership usage reporting |
| `MyTeeTimes.php` / `MyActivityBookings.php` | Member booking history |
| `PromoCode.php` / `Punchcards.php` | Promos + punch cards |
| `Dir.php` | Member directory |

---

## Total Count

| Category | Count |
|---|---|
| **Total repos in stable codebase** | 5 |
| **Backend .NET projects (golfler_asp_2)** | 16 |
| **Desktop app projects (golfler_pos_2)** | 4 |
| **Angular feature modules (sgs-cts-angular)** | ~20 |
| **PHP controllers — cc_api_manager** | ~20 |
| **PHP controllers — cc_membership_portal** | ~20 |
| **Active** | 14 backend + all frontend |
| **Deprecated/Legacy** | CourseWebApi, POS (WinForms), paymentV1, controllers_old/ |
