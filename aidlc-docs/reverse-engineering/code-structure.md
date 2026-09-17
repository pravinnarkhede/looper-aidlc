# Code Structure — Golfler / ClubCaddie Platform

**Source**: Live codebase scan — `stable-codebase\` (2026-06-10)

---

## Build Systems

| Repo | Build System | Key Config File |
|---|---|---|
| golfler_asp_2 | MSBuild + NuGet | `Golfler.sln`, `PosApi\PosApi.csproj`, per-project `packages.config` |
| golfler_pos_2 | MSBuild + NuGet | `POSApp\POSApp.sln`, `POSApp\POSApp\POSApp.csproj` |
| sgs-cts-angular | Angular CLI + npm | `angular.json`, `package.json`, `package-lock.json` |
| cc_api_manager | None (PHP, no build step) | `.htaccess`, `application/config/` |
| cc_membership_portal | None (PHP, no build step) | `.htaccess`, `application/config/` |

---

## golfler_asp_2 — Key Source Files

### GolflerShared (Shared Business Logic — ⚠️ CRITICAL)

Compiled into PosApi, GolferWebAPI, Golfler, and CourseWebApi. Changes here affect all simultaneously.

| File | Purpose |
|---|---|
| `Modules\Order.cs` | Order processing core logic |
| `Modules\Payment.cs` | Payment gateway dispatch — **EXTREME RISK** |
| `Modules\PaymentType.cs` | Payment type constants |
| `Modules\PaymentMethods.cs` | Payment method utilities |
| `Modules\RefundsHandler.cs` | Refund processing |
| `Modules\TeeBooking.cs` | Tee time booking logic |
| `Modules\Teesheet.cs` | Tee sheet management |
| `Modules\Membership.cs` | Membership business logic |
| `Modules\MembershipLedger.cs` | Membership ledger |
| `Modules\MembershipInvoice.cs` | Invoice generation |
| `Modules\MembershipGroup.cs` | Group membership |
| `Modules\Event.cs` | Event/tournament management |
| `Modules\Customer\CustomerBusiness.cs` | Customer business logic |
| `Modules\CommonFunctions.cs` | Utility helpers |
| `Modules\CommonProperties.cs` | `WebSetting` class — all setting name constants |
| `Modules\ConfigClass.cs` | Configuration management |
| `Modules\Setting.cs` | Settings access pattern |
| `Modules\CourseClass.cs` | Course data access |
| `Modules\CourseProducts.cs` | Course product management |
| `Modules\Wallet.cs` | Customer wallet |
| `Modules\Encryption.cs` | Encryption utilities |
| `Modules\Firebase.cs` | Push notification dispatch |
| `Modules\ReservationsSheet.cs` | Reservations logic |
| `Modules\LotterySheet.cs` | Lottery tee sheet |
| `Modules\RecordChangelog.cs` | Audit trail |
| `Modules\StaticProperties.cs` | Static application properties |
| `Modules\Types.cs` | Type definitions |
| `Modules\Rangefinder.cs` | Rangefinder integration |
| `Modules\FirstPay\FirstPayIntegration.cs` | FirstPay gateway |
| `Modules\CardConnect\CardConnectIntegration.cs` | CardConnect gateway |
| `Modules\CloverConnect\CloverAccounts.cs` | Clover gateway |
| `Modules\Spreedly\SpreedlyIntegration.cs` | Spreedly gateway |
| `Modules\QBO\QBOOauth.cs` | QuickBooks Online auth |
| `Modules\CampaignMonitor\CampaignMonitor.cs` | Email campaigns |
| `Modules\CriticalImpact\CriticalImpact.cs` | CRM integration |
| `Modules\LightSpeed\Sale.cs` | LightSpeed aggregator |
| `Modules\RedWater\RedwaterCustomer.cs` | RedWater aggregator |
| `Modules\X-Golf\XGolfDataAccess.cs` | XGolf integration |

### GolflerDataModel

| File | Purpose |
|---|---|
| `Models\GolflerDataModel.edmx` | EF6 EDMX — defines all 431 GF_ entity classes |
| `Models\GolflerDataModel.Context.cs` | `GolflerDataModelEntities` DbContext — the main data access entry point |
| `Models\GolflerDataModel.tt` | T4 template generating entity classes |
| `Modules\RedisCache\` | Redis cache module |

### PosApi

| File/Path | Purpose |
|---|---|
| `Controllers\CourseController.cs` | Settings, course configuration — large/central |
| `Controllers\OrderController.cs` | Order management |
| `Controllers\CustomersController.cs` | Customer operations |
| `Controllers\MembershipController.cs` (via `Membership/`) | Membership operations |
| `Controllers\TeeBookingsController.cs` | Staff tee time booking |
| `Controllers\CreditVoucherController.cs` | Voucher management |
| `Controllers\ReportController.cs` | Reporting |
| `Controllers\AiChat\AiChatController.cs` | AI chat functionality |
| `Controllers\ChartOfAccount\ChartOfAccountsController.cs` | GL chart of accounts |
| `Controllers\CourseEvents\EventsController.cs` | Event management |
| `Controllers\Membership\MembershipInvoiceController.cs` | Membership invoicing |
| `Workers\ClubWideMonthlyMembershipBillingJob.cs` | Hangfire: monthly billing |
| `Workers\ClubWideMonthlyMembershipChargeJob.cs` | Hangfire: monthly charge |
| `Workers\MembershipDateSpecificBillingJob.cs` | Hangfire: date billing |
| `Workers\MembershipDateSpecificChargeJob.cs` | Hangfire: date charge |
| `Workers\DeActivateExpiredCustomerClassTypeJob.cs` | Hangfire: class type expiry |

### GolferWebAPI

| File/Path | Purpose |
|---|---|
| `Models\TeeBooking.cs` | Core tee time booking logic |
| `Models\OnlinePaymentsHandler.cs` | Online payment validation + processing |
| `Models\CreditVoucher.cs` | Voucher lookup, sale, search |
| `Controllers\OnDemandController.cs` | On-demand ordering |
| `Controllers\TeeBookingController.cs` | Customer tee booking |
| `Controllers\TeeTimesV2Controller.cs` / `TeeTimesV3Controller.cs` | Tee time availability (v2/v3) |
| `Controllers\MembershipController.cs` (via `Membership/`) | Member-facing membership |
| `Controllers\CustomerController.cs` | Customer profile |
| `Controllers\Membership\CreditVoucherController.cs` | Voucher operations |
| `Controllers\Membership\MembershipSaleController.cs` (via `MembershipSale/`) | Membership purchase |
| `Controllers\AggregatorIntegration\TeeTimesController.cs` | Aggregator tee times |
| `Controllers\CCInterface\V1\CCInterfaceCustomersController.cs` | Cross-club customers |

---

## golfler_pos_2 — Key Source Files

| File | Purpose |
|---|---|
| `POSApp\App.xaml` / `App.xaml.cs` | Application entry point |
| `POSApp\BootStrapper.cs` | Application bootstrap / IoC |
| `POSApp\ApplicationData.cs` | App-wide shared state |
| `POSApp\ApplicationEventsCoordinator.cs` | Event coordination |
| `POSApp\IViewModel.cs` / `ViewModelBase.cs` | MVVM base classes |
| `POSApp\LandingViewModel.cs` / `LoginViewModel.cs` | Top-level ViewModels |
| `POSApp\ViewModels\` | 100+ ViewModels covering all POS screens |
| `POSApp\ViewModels\EventManager\` | GolfLeague, GolfOuting, Banquet, Activity VMs |
| `POSApp\ViewModels\CRM\` | CRM centre, customer, dashboard VMs |
| `POSApp\DialogWindows\` | 100+ XAML popup/dialog windows |
| `POSApp\DialogWindows\Members\` | Membership-specific dialogs |
| `POSApp\Behaviours\CustomScheduleViewDragDropBehavior.cs` | Tee sheet drag/drop |
| `POSApp\Behaviours\ExportPDF.cs` | PDF export behavior |
| `POSApp\Controls\TouchScreenKeyboard.cs` | Custom touch keyboard |
| `POSApp\Controls\TeeTimeIntervalControl.cs` | Tee time interval control |
| `POSApp\BluePay\BluePay.cs` | BluePay payment gateway integration |
| `POSApp\App_Code\AddInventoryQuickBooks.cs` | QuickBooks inventory sync |
| `POSApp\Common\SharpPDFLabel\` | Avery label PDF generation |
| `POSApp\ApplicationModules\EventBroadcast\EventBroadcastManager.cs` | Event bus |
| `POSApp\ApplicationModules\Logging\ApplicationLogger.cs` | Application logging |

---

## sgs-cts-angular — Key Source Files

| File | Purpose |
|---|---|
| `src/app/app.module.ts` | Root Angular module |
| `src/app/app-routing.module.ts` | Route definitions (50+ routes) |
| `src/app/auth.guard.ts` | Route authentication guard |
| `src/app/service/authentication.service.ts` | Login/auth service |
| `src/app/service/register.service.ts` | POS register operations |
| `src/app/service/tee-sheet.service.ts` | Tee sheet data service |
| `src/app/service/openai.service.ts` | OpenAI integration |
| `src/app/service/print.service.ts` | Print handling |
| `src/app/service/card-swipe.service.ts` | Card swipe handling |
| `src/app/service/looper-token-validation.service.ts` | Token validation |
| `src/app/service/iframe-setting.service.ts` | iFrame settings |
| `src/app/common-service/CommonConstants.ts` | Application constants |
| `src/app/common-service/CommonUtilities.ts` | Utility functions |
| `src/app/common-service/DateUtilities.ts` | Date helpers |
| `src/app/DataAccessHelper/card-connect-data-access.ts` | CardConnect client |
| `src/app/DataAccessHelper/clover-connect-data-access.ts` | CloverConnect client |

---

## cc_api_manager — Key Source Files

| File | Purpose |
|---|---|
| `application/controllers/Webapi.php` | Central API proxy controller |
| `application/controllers/Manager.php` | Admin entry point |
| `application/models/API_Model.php` | HTTP proxy to GolferWebAPI — all data operations go here |
| `application/libraries/MY_Session.php` | Custom session management |
| `application/hooks/CountryBlock.php` | Geo-blocking hook |
| `application/config/{env}/constants.php` | Per-environment configuration (cc1, sg2, sg3, sit1, sit2, uat, uat1, rhodes, tribute...) |

---

## cc_membership_portal — Key Source Files

| File | Purpose |
|---|---|
| `application/core/MY_Controller.php` | Base controller — shared auth/session logic |
| `application/controllers/Auth.php` | Member authentication |
| `application/controllers/Member.php` | Main member portal |
| `application/models/API_Model.php` | HTTP proxy to GolferWebAPI/PosApi |
| `application/libraries/Excel.php` | Excel export |
| `application/libraries/M_pdf.php` | PDF generation |
| `application/helpers/my_helper.php` | Custom helper functions |
| `application/hooks/CountryBlock.php` | Geo-blocking |
| `application/controllers_old/` | Archived previous implementation (Auth.php, Member.php) |
| `application/controllers_1/` | Alternate controller set (Auth.php, Member.php) |

---

## Design Patterns

### MVVM (golfler_pos_2)
- **Location**: All of `POSApp\ViewModels\`, `POSApp\IViewModel.cs`, `POSApp\ViewModelBase.cs`
- **Purpose**: Standard WPF MVVM — separates UI (XAML) from logic (ViewModels)
- **Implementation**: `ViewModelBase` extends `Bindable`, implements `IViewModel`

### Database-First EF6 EDMX (golfler_asp_2)
- **Location**: `GolflerDataModel\Models\GolflerDataModel.edmx`
- **Purpose**: Single source of truth for all 431 GF_ entity classes
- **Implementation**: EDMX auto-generates entity classes via T4 templates; consumed via `GolflerDataModelEntities` DbContext

### Shared Project Pattern (golfler_asp_2)
- **Location**: `GolflerShared\` (.shproj)
- **Purpose**: Share business logic across ASP.NET projects without a DLL reference
- **Implementation**: `.projitems` compiled directly into each consuming project — no separate assembly

### HTTP Proxy Model (cc_api_manager, cc_membership_portal)
- **Location**: `application/models/API_Model.php` in both PHP repos
- **Purpose**: PHP apps have no direct DB access — all data goes through HTTP calls to .NET APIs
- **Implementation**: `API_Model.php` is the single data access layer; it wraps all GolferWebAPI calls

### Multi-Tenant CourseId Filtering
- **Location**: Every controller and data access layer across golfler_asp_2
- **Purpose**: Prevent data leakage between course tenants
- **Implementation**: Application-layer — every query must include `CourseId`; no DB-level row security

---

## Critical Dependencies

### IronPdf.Slim
- **Version**: 2024.6.1 (in PosApi.csproj)
- **Usage**: PDF generation in PosApi
- **Purpose**: Server-side PDF creation for receipts and reports

### Telerik UI for WPF
- **Version**: 2019.2.618.45 (trial assemblies in `Binary/`)
- **Usage**: All tee sheet UI, grids, scheduling views in PosApp
- **Purpose**: Enterprise-grade WPF controls — tee sheet drag/drop via RadScheduleView

### Entity Framework 6
- **Version**: 6.4.4 (in PosApi packages)
- **Usage**: All database access throughout golfler_asp_2
- **Purpose**: Database-first EDMX ORM for all 431 GF_ tables

### Hangfire
- **Usage**: Hosted in PosApi; membership billing jobs
- **Purpose**: Recurring background job scheduler (monthly billing, date-specific billing, class type expiry)
