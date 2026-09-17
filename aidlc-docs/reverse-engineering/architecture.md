# System Architecture — Golfler / ClubCaddie Platform

**Source**: Live codebase scan — `stable-codebase\` (2026-06-10)

---

## System Overview

Golfler is a monolithic, multi-tenant golf course management platform. The core backend is a single ASP.NET solution (`golfler_asp_2`) exposing two Web APIs — **PosApi** (staff-facing) and **GolferWebAPI** (customer-facing). All business logic lives in the .NET backend; PHP and Angular repos are thin rendering/UI layers that proxy to those APIs.

Multi-tenancy is enforced at the application layer: every database query must include `CourseId`. There is no row-level security at the database level.

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        GOLFLER PLATFORM                             │
│                                                                     │
│  STAFF CLIENTS                     CUSTOMER CLIENTS                 │
│  ┌───────────────────┐             ┌───────────────────────────┐    │
│  │ WPF PosApp        │             │ cc_membership_portal      │    │
│  │ (golfler_pos_2)   │             │ (PHP CodeIgniter)         │    │
│  ├───────────────────┤             ├───────────────────────────┤    │
│  │ Angular CCOnline  │             │ cc_api_manager            │    │
│  │ (sgs-cts-angular) │             │ (PHP CodeIgniter — iFrame)│    │
│  ├───────────────────┤             ├───────────────────────────┤    │
│  │ Golfler Admin MVC │             │ cc_ios / cc_android       │    │
│  │ (golfler_asp_2)   │             │ (Swift / Kotlin — external)    │
│  └────────┬──────────┘             └────────────┬──────────────┘    │
│           │                                     │                   │
│           ▼                                     ▼                   │
│  ┌────────────────┐              ┌──────────────────────────┐       │
│  │   PosApi       │              │     GolferWebAPI         │       │
│  │ (Web API 2)    │              │  (Web API 2 / .NET 4.6.1)│       │
│  └────────┬───────┘              └─────────────┬────────────┘       │
│           │                                    │                    │
│           └───────────────┬────────────────────┘                    │
│                           │                                         │
│           ┌───────────────▼────────────────┐                        │
│           │  GolflerShared (.projitems)     │                        │
│           │  GolflerDataModel (EF6 EDMX)   │                        │
│           └───────────────┬────────────────┘                        │
│                           │                                         │
│           ┌───────────────▼────────────────┐                        │
│           │  SQL Server — GolflerF DB       │                        │
│           │  431 tables (GF_ prefix)        │                        │
│           │  Hangfire background jobs       │                        │
│           └────────────────────────────────┘                        │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Component Descriptions

### golfler_asp_2 — Backend (.NET Solution)
- **Purpose**: All APIs, database schema, and business logic for the platform
- **Responsibilities**: Staff operations (PosApi), customer/mobile operations (GolferWebAPI), admin portal (Golfler MVC), EF6 data model, shared business logic (GolflerShared), SQL Server schema (GolflerDB)
- **Dependencies**: SQL Server (GolflerF), Redis cache, Azure Blob Storage, external payment gateways, Hangfire
- **Type**: Application + Infrastructure
- **Framework**: ASP.NET MVC 5 / Web API 2, .NET 4.6.1–4.7.2

### golfler_pos_2 — WPF Desktop POS
- **Purpose**: Staff point-of-sale terminal for course operations
- **Responsibilities**: Order taking, payments, tee time management, event management, membership operations, reports
- **Dependencies**: PosApi (HTTP), Telerik UI for WPF 2019.2, BluePay payment gateway
- **Type**: Application (desktop)
- **Framework**: WPF/MVVM, .NET 4.7.1

### sgs-cts-angular — CCOnline Angular Web App
- **Purpose**: Web-based staff management interface (CCOnline)
- **Responsibilities**: POS register, tee sheet, customers, events, reports, settings, on-demand ordering
- **Dependencies**: PosApi (HTTP via proxy), Angular 10, Angular Material, Pusher (real-time), OpenAI service
- **Type**: Application (web frontend)
- **Framework**: Angular 10, TypeScript 4.0.5

### cc_api_manager — iFrame Booking Widgets (PHP)
- **Purpose**: Powers online tee time booking iFrames embedded on club websites
- **Responsibilities**: Booking iFrames, membership sale iFrames, event registration, voucher purchase, online payment flow
- **Dependencies**: GolferWebAPI (all data via HTTP proxy through API_Model.php), multi-environment constants
- **Type**: Application (PHP web)
- **Framework**: CodeIgniter 3.x

### cc_membership_portal — Customer Self-Service Portal (PHP)
- **Purpose**: Online member portal for self-service account management
- **Responsibilities**: Member login, tee time booking, event registration, voucher management, membership usage, bulletin board
- **Dependencies**: GolferWebAPI + PosApi (via API_Model.php HTTP proxy), Excel.php, M_pdf.php
- **Type**: Application (PHP web)
- **Framework**: CodeIgniter 3.x

---

## Data Flow

```
[Staff] → sgs-cts-angular / golfler_pos_2
            ↓ HTTP
          PosApi → GolflerShared → GolflerDataModel → SQL Server (GolflerF)

[Customer] → cc_membership_portal / cc_api_manager / cc_ios / cc_android
              ↓ HTTP (all data via API_Model.php)
            GolferWebAPI → GolflerShared → GolflerDataModel → SQL Server (GolflerF)

[Background] → Hangfire (hosted in PosApi)
               → Membership billing jobs (ClubWideMonthlyMembershipBillingJob, etc.)
               → AzureUtilities (Azure Functions — GL uploads, background jobs)
```

---

## Integration Points

- **Payment Gateways**: AuthorizeNet, Braintree, Stripe, BluePay, CardConnect, CloverConnect, Spreedly, BasysCard (all integrated via GolflerShared/Modules)
- **CRM**: HubSpot (HubSpotIntegration Azure Function), CampaignMonitor, CriticalImpact
- **Accounting**: QuickBooks Online (QBO OAuth), Oracle, Great Plains (chart of account extensions)
- **Aggregators**: Forefront, ORCA, LightSpeed, RedWater, X-Golf, XGolf
- **Push Notifications**: PushSharp (iOS/Android), Firebase, Pusher (real-time channels)
- **Storage**: Azure Blob (AzureUtilities), SFTP (Renci.SshNet)
- **PDF/Reports**: IronPdf.Slim 2024.6.1, jsPDF (Angular), pdfmake, M_pdf (PHP)
- **Range**: Rangefinder, RangeExpress Azure Function

---

## Infrastructure Components

- **CI/CD**: Jenkins (Groovy pipelines in `JenkinsAutomation\PipelineScripts\`)
  - `ASP_Deployment.groovy` — deploys PosApi, GolferWebAPI, Golfler MVC (selectable per Boolean flags)
  - `CMDB_Deployment.groovy`, `Multiple_GolferF_Deployment.groovy`, `Single_GolferF_Deployment.groovy`
  - Source: Bitbucket `git@bitbucket.org:definelabs/golfler_asp_2.git`
  - Target environment: `CCAZUREDEV2` (dev), plus prod configs
- **Database**: SQL Server, database `GolflerF`, 431 tables with `GF_` prefix, multi-tenant via `CourseId`
- **Background Jobs**: Hangfire (hosted in PosApi), Azure Functions (`AzureUtilities`)
- **Deployment**: Azure Web Deploy / Zip Deploy (publish profiles in `AzureUtilities\Properties\PublishProfiles\`)
- **IIS**: IIS Express (`applicationhost.config`), production via IIS
