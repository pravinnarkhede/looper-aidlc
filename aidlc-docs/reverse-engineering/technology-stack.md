# Technology Stack — Golfler / ClubCaddie Platform

**Source**: Live codebase scan — `stable-codebase\` (2026-06-10)

---

## Programming Languages

| Language | Version | Repos | Usage |
|---|---|---|---|
| C# | .NET 4.5.2–4.7.2 / Core 3.1 | golfler_asp_2, golfler_pos_2 | All backend, desktop POS |
| TypeScript | 4.0.5 | sgs-cts-angular | Angular CCOnline web app |
| PHP | 7.x (CI 3.x compatible) | cc_api_manager, cc_membership_portal | iFrame widgets, customer portal |
| SQL (T-SQL) | SQL Server | golfler_asp_2 | 431-table GolflerF DB + stored procs |
| JavaScript | ES5/ES6 | sgs-cts-angular (vendor), Golfler MVC | jQuery, vendor scripts (~638K lines in Golfler) |
| Groovy | — | golfler_asp_2 | Jenkins CI/CD pipeline scripts |
| XAML | — | golfler_pos_2 | WPF UI markup |

---

## Frameworks

| Framework | Version | Repo | Purpose |
|---|---|---|---|
| ASP.NET MVC 5 | 5.x | golfler_asp_2 (Golfler) | Admin web portal |
| ASP.NET Web API 2 | 2.x | golfler_asp_2 (PosApi, GolferWebAPI) | Staff + customer REST APIs |
| ASP.NET Core Web API | 3.1 | golfler_asp_2 (CCACHWebhook, CCU) | Modern utility APIs |
| Entity Framework 6 | 6.4.4 | golfler_asp_2 | Database-first ORM (EDMX), 431 tables |
| WPF (Windows Presentation Foundation) | .NET 4.7.1 | golfler_pos_2 | Desktop POS UI framework |
| Angular | 10 (~10.2.4) | sgs-cts-angular | Web staff management app |
| Angular Material | 10 (^10.2.7) | sgs-cts-angular | UI component library |
| CodeIgniter | 3.x | cc_api_manager, cc_membership_portal | PHP MVC framework |
| Hangfire | — | golfler_asp_2 | Background job scheduling |

---

## UI Libraries & Controls

| Library | Version | Repo | Purpose |
|---|---|---|---|
| Telerik UI for WPF | 2019.2.618.45 | golfler_pos_2 | RadScheduleView (tee sheet), RadGridView, etc. |
| ngx-bootstrap | 5.5.0 | sgs-cts-angular | Bootstrap Angular integration |
| Bootstrap | 4 | sgs-cts-angular | CSS framework |
| PrimeNG | 8 | sgs-cts-angular | Angular UI components |
| Angular Calendar | 0.27.11 | sgs-cts-angular | Calendar component |
| GoJS | 2.3.17 | sgs-cts-angular | Diagram/flow visualization |

---

## Infrastructure & Cloud

| Service | Repo | Purpose |
|---|---|---|
| SQL Server | golfler_asp_2 | Primary database (GolflerF, 431 tables) |
| Azure Blob Storage | golfler_asp_2 | File storage (AzureUtilities) |
| Azure Functions | golfler_asp_2 | Background jobs (GL uploads, HubSpot sync, RangeExpress) |
| Azure Web Deploy | golfler_asp_2 | Deployment mechanism (publish profiles) |
| Redis Cache | golfler_asp_2 (GolflerDataModel) | Session/data caching (`GolflerDataModel.Modules.RedisCache`) |
| IIS / IIS Express | golfler_asp_2 | Web hosting |
| Pusher | sgs-cts-angular | Real-time channel events (pusher-js 7.0.2) |
| Firebase | golfler_asp_2 (GolflerShared) | Push notifications (`GolflerShared\Modules\Firebase.cs`) |
| Jenkins | golfler_asp_2 | CI/CD (Bitbucket → MSBuild → Azure deploy) |

---

## Payment Gateways

| Gateway | Integration Point | Location |
|---|---|---|
| AuthorizeNet | GolflerShared | `Binaries\AuthorizeNet.dll` |
| Braintree | GolflerShared | `Binaries\Braintree-2.41.0.dll` |
| Stripe | GolflerShared | `Binaries\Stripe.net.dll` |
| BluePay | golfler_pos_2 | `POSApp\BluePay\BluePay.cs` |
| CardConnect | GolflerShared | `Modules\CardConnect\CardConnectIntegration.cs` |
| CloverConnect | GolflerShared | `Modules\CloverConnect\CloverAccounts.cs` |
| Spreedly | GolflerShared | `Modules\Spreedly\SpreedlyIntegration.cs` |
| BasysCard | PosApi | `Controllers\BasysController.cs`, `BasysCardSaveController.cs` |
| FirstPay | GolflerShared | `Modules\FirstPay\FirstPayIntegration.cs` |

> **Risk**: Payment code lives in GolflerShared — compiled into EVERY consuming project. Any change affects PosApi, GolferWebAPI, and Golfler MVC simultaneously.

---

## Build Tools

| Tool | Version | Usage |
|---|---|---|
| MSBuild | — | .NET solution builds (golfler_asp_2, golfler_pos_2) |
| NuGet | — | .NET package management (packages.config per project) |
| Angular CLI | 10.2.2 | Angular build/serve/test (`@angular-devkit/build-angular ~0.1002.1`) |
| npm | — | Angular + Node dependency management |
| Jenkins | — | CI/CD orchestration (Groovy pipelines) |
| Apache mod_rewrite | — | PHP CodeIgniter URL routing (.htaccess) |

---

## Testing Tools

| Tool | Version | Repo | Purpose |
|---|---|---|---|
| MSTest | — | golfler_asp_2 (PosApiUnitTest) | 2 stub test files (MembershipControllerTest, PurchaseInvoiceControllerTest) |
| MSTest | — | golfler_pos_2 (POSUnitTest) | Unit test project (content not examined) |
| Jasmine | — | sgs-cts-angular | Angular unit test framework |
| Karma | — | sgs-cts-angular | Angular test runner |
| Protractor | — | sgs-cts-angular | Angular E2E test runner (`e2e/protractor.conf.js` present) |
| tslint | 6.1.0 | sgs-cts-angular | TypeScript linting |
| codelyzer | 5.1.2 | sgs-cts-angular | Angular-specific lint rules |

---

## Key Third-Party Libraries

| Library | Version | Repo | Purpose |
|---|---|---|---|
| IronPdf.Slim | 2024.6.1 | golfler_asp_2 (PosApi.csproj line 3) | PDF generation |
| PushSharp | — | golfler_asp_2 | iOS + Android push notifications |
| PusherServer | — | golfler_asp_2 | Server-side Pusher integration |
| RestSharp | — | golfler_asp_2 | HTTP client for external API calls |
| Renci.SshNet | — | golfler_asp_2 | SFTP file transfers |
| Telerik UI for WPF | 2019.2.618.45 | golfler_pos_2 | WPF POS UI controls |
| ExcelJS | 4.4.0 | sgs-cts-angular | Excel export |
| jsPDF | 1.5.3 | sgs-cts-angular | PDF generation (client-side) |
| Chart.js | 2.9.4 | sgs-cts-angular | Charting |
| node-thermal-printer | ^2.0.0 | sgs-cts-angular | Thermal receipt printing |
| openai | — | sgs-cts-angular | OpenAI integration (`openai.service.ts`) |
| Excel.php | — | cc_membership_portal | Server-side Excel export |
| M_pdf.php | — | cc_membership_portal | Server-side PDF generation |
