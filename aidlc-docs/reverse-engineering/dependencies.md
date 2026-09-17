# Dependencies — Golfler / ClubCaddie Platform

**Source**: Live codebase scan — `stable-codebase\` (2026-06-10)

---

## Internal Project Dependencies

```
golfler_asp_2 (Golfler.sln)
│
├── GolflerShared (.shproj — compiled into all below)
│   └── [Payment, TeeBooking, Membership, Order, CommonProperties, ...]
│
├── GolflerDataModel (Class Library — EF6 EDMX)
│   └── Provides GolflerDataModelEntities DbContext to all .NET projects
│
├── PosApi (Web API 2)
│   ├── depends on: GolflerShared (via .projitems)
│   ├── depends on: GolflerDataModel (DLL reference)
│   └── hosts: Hangfire jobs (Workers/)
│
├── GolferWebAPI (Web API 2)
│   ├── depends on: GolflerShared (via .projitems)
│   └── depends on: GolflerDataModel (DLL reference)
│
├── Golfler (ASP.NET MVC 5)
│   ├── depends on: GolflerShared (via .projitems)
│   └── depends on: GolflerDataModel (DLL reference)
│
├── CourseWebApi (Web API 2 — DEPRECATED)
│   ├── depends on: GolflerShared (via .projitems)
│   └── depends on: GolflerDataModel (DLL reference)
│
├── CCU (ASP.NET Core)           — standalone, no GolflerShared
├── CCACHWebhook (ASP.NET Core)  — standalone, no GolflerShared
├── AzureUtilities (Azure Func)  — standalone
├── HubSpotIntegration           — standalone
├── RangeExpress                 — standalone
├── VoucherExpirationWindowsService — may use GolflerDataModel
└── MaintenanceConsoleApp        — may use GolflerDataModel

golfler_pos_2 (POSApp.sln)
│
├── POSApp (WPF)
│   └── depends on: POSApp.Data, POSApp.Core
│
├── POSApp.Data (Class Library)
│   └── API contracts for PosApi HTTP calls
│
└── POSApp.Core (Class Library)
    └── Shared utilities

sgs-cts-angular
└── No internal sub-packages; single Angular app consuming PosApi over HTTP

cc_api_manager
└── No internal modules; single CI3 app consuming GolferWebAPI via API_Model.php

cc_membership_portal
└── No internal modules; single CI3 app consuming GolferWebAPI/PosApi via API_Model.php
```

---

## Cross-Repo Runtime Dependencies

| Client | Depends On | Mechanism |
|---|---|---|
| golfler_pos_2 | PosApi (golfler_asp_2) | HTTP REST calls from `POSApp.Data\ApiContracts\` |
| sgs-cts-angular | PosApi (golfler_asp_2) | HTTP REST (Angular services, dev proxy in `proxy.config.json`) |
| cc_api_manager | GolferWebAPI (golfler_asp_2) | HTTP via `API_Model.php` |
| cc_membership_portal | GolferWebAPI (golfler_asp_2) | HTTP via `API_Model.php` |
| cc_ios / cc_android (external) | GolferWebAPI (golfler_asp_2) | HTTP REST |

---

## External Dependencies — golfler_asp_2

### NuGet Packages (Key)

| Package | Version | Purpose |
|---|---|---|
| EntityFramework | 6.4.4 | ORM (database-first EDMX) |
| IronPdf.Slim | 2024.6.1 | PDF generation |
| Hangfire | — | Background job scheduling |
| NLog | — | Logging |
| RestSharp | — | HTTP client for external APIs |
| Microsoft.Azure.* | — | Azure SDK (Blob, Functions) |
| MSTest.TestAdapter | — | Test adapter for PosApiUnitTest |

### Binary Dependencies (Binaries/)

| DLL | Version | Purpose |
|---|---|---|
| AuthorizeNet.dll | — | AuthorizeNet payment gateway |
| Braintree-2.41.0.dll | 2.41.0 | Braintree payment gateway |
| Stripe.net.dll | — | Stripe payment gateway |
| PushSharp.Android.dll | — | Android push notifications |
| PushSharp.Apple.dll | — | iOS push notifications |
| PushSharp.Core.dll | — | Push notification core |
| PusherServer.dll | — | Pusher real-time server |
| RestSharp.dll | — | HTTP client |
| Renci.SshNet.dll | — | SFTP transfers |
| TemplateParser.Modificators.dll | — | Template parsing |
| ErrorLibrary.dll | — | Custom error handling |
| commonlibrary.dll | — | Define Labs shared utilities |
| Golfler.dll | — | Pre-compiled Golfler assembly |

---

## External Dependencies — golfler_pos_2

### NuGet Packages (Key)

| Package | Version | Purpose |
|---|---|---|
| Telerik UI for WPF | 2019.2.618.45 | All WPF controls (tee sheet, grids) |
| Microsoft.Toolkit.Win32.UI.XamlApplication | 6.1.2 | WPF/UWP integration |
| Microsoft.Windows.SDK.Contracts | 10.0.18362.2005 | Windows SDK |
| WPFToolkit | 3.5.50211.1 | WPF toolkit extensions |

---

## External Dependencies — sgs-cts-angular

### npm Packages (Key)

| Package | Version | Purpose |
|---|---|---|
| @angular/core | ~10.2.4 | Angular framework |
| @angular/material | ^10.2.7 | Material UI components |
| rxjs | 6.6.3 | Reactive extensions |
| ngx-bootstrap | 5.5.0 | Bootstrap integration |
| pusher-js | 7.0.2 | Real-time Pusher channels |
| chart.js | 2.9.4 | Charts |
| exceljs | 4.4.0 | Excel generation |
| jspdf | 1.5.3 | PDF generation |
| openai | — | OpenAI API client |
| node-thermal-printer | ^2.0.0 | Thermal receipt printing |
| electron | 3 | Desktop app packaging |
| gojs | 2.3.17 | Diagram visualization |
| @kolkov/angular-editor | — | Rich text editor |
| angular-azure-blob-service | — | Azure Blob uploads |
| ngx-barcode | — | Barcode rendering |

---

## External Dependencies — PHP Repos

### cc_api_manager

| Dependency | How Provided | Purpose |
|---|---|---|
| CodeIgniter 3.x | Bundled in `system/` | MVC framework |
| No Composer packages | — | All deps manually bundled |

### cc_membership_portal

| Dependency | How Provided | Purpose |
|---|---|---|
| CodeIgniter 3.x | Bundled in `system/` | MVC framework |
| Excel.php (PHPExcel variant) | `application/libraries/` | Excel export |
| M_pdf.php | `application/libraries/` | PDF generation |

---

## Runtime Infrastructure Dependencies

| Infrastructure | Used By | Purpose |
|---|---|---|
| SQL Server (GolflerF) | golfler_asp_2 | All data storage |
| Redis | golfler_asp_2 | Session/data cache |
| Azure Blob Storage | golfler_asp_2 | File storage |
| Azure Function runtime | golfler_asp_2 (AzureUtilities) | Background processing |
| Jenkins | golfler_asp_2 | CI/CD deployments |
| Bitbucket (SSH) | All repos | Source control (`git@bitbucket.org:definelabs/`) |
| IIS (Windows) | golfler_asp_2 | Web hosting (.NET apps) |
| Apache (PHP) | cc_api_manager, cc_membership_portal | Web hosting (PHP apps) |
