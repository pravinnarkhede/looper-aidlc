# API Documentation — Golfler / ClubCaddie Platform

**Source**: Live codebase scan — `stable-codebase\` (2026-06-10)

> Full OpenAPI specs are available at:
> - `stable-codebase\golfler_asp_2\docs\api\posapi-openapi.json` (1.7 MB)
> - `stable-codebase\golfler_asp_2\docs\api\golferwebapi-openapi.json` (542 KB)
>
> The sections below provide a structural overview by controller domain.

---

## PosApi — Staff REST API

**Base URL**: `{course-server}/PosApi`  
**Auth**: Token-based (`ApiUserTokenMandatoryAuthorizationFilter`)  
**Consumer clients**: golfler_pos_2, sgs-cts-angular, Golfler MVC

### Controller Domains

| Domain | Controllers | Purpose |
|---|---|---|
| **Orders** | `OrderController`, `OrderDetailsPreperationsDocketController` | Order creation, modification, dockets |
| **Payments** | `BasysController`, `BasysCardSaveController`, `CreditCardTerminalController`, `CustomPaymentTypeController`, `DelieverNPaymentController` | Payment processing per gateway |
| **Customers** | `CustomersController`, `CustomersGroupController`, `CustomerClassTypeController`, `CustomerDiscountRuleController` | Customer CRUD, groups, class types, discounts |
| **Tee Times** | `TeeBookingsController` | Staff tee time booking and management |
| **Memberships** | `Membership/MembershipController`, `Membership/MembershipInvoiceController` | Membership admin, invoicing |
| **Credit Vouchers** | `CreditVoucherController`, `CreditVoucherLedgerController` | Voucher issuance, redemption, ledger |
| **Inventory** | *(InventoryManagement/ controllers)* | Product catalog, stock management |
| **Events** | `CourseEvents/EventsController`, `CourseEvents/EventCustomersController`, `CourseEvents/EventGolfersController`, `CourseEvents/EventTransactionController`, `CourseEvents/EventProductsController`, `CourseEvents/VenueScheduleController` | Event/tournament management |
| **Activities** | `CourseEvents/ActivityLeagueController`, `CourseEvents/ActivityOutingEventController`, `CourseEvents/GolfLeagueCheckinController` | League, outing, activity management |
| **Courses** | `CourseController` | Course configuration, settings (large central controller) |
| **Reports** | `ReportController`, `CardConnectPaymentsReportController`, `CloverPaymentsReportController` | Financial and operational reports |
| **Chart of Accounts** | `ChartOfAccount/ChartOfAccountsController`, `ChartOfAccount/ChartOfAccountsGreatPlainsExtensionController`, `ChartOfAccount/ChartOfAccountsOracleExtensionController` | GL accounts with ERP extensions |
| **Purchase** | `PurchaseOrders/PurchaseOrdersController`, `PurchaseInvoice/PurchaseInvoiceController` | Purchase orders and supplier invoices |
| **Cash** | `CashPayoutController` | Cash management and payout |
| **CRM** | `CRM/CampaignsController`, `CommunicationEmailController`, `CommunicationsMailerController`, `CommunicationWebhookController` | Email campaigns, comms |
| **Bulletin** | `BulletinBoardController` | Bulletin board management |
| **AI** | `AiChat/AiChatController` | AI chat functionality |
| **Admin** | `AdminUserController`, `AuthorizedController`, `AzureController` | Admin users, auth, Azure ops |
| **Integrations** | `CampaignMonitor/CampaignMonitorController`, `CriticalImpact/CriticalImpactController`, `YellowDog/YellowDogTransactionsController`, `AptechIntegrationController`, `CapPatrolIntegrationController`, `CardConnectWebhookController` | Third-party integrations |
| **Data** | `DataSanityController`, `DebugController` | Maintenance and debug |
| **Active Rates** | `ActiveRatesController` | Pricing and rate management |
| **Address** | `AddressController` | Address management |
| **Class Rules** | `ClassRulesController`, `ClassTypeController` | Customer class management |
| **Channel Partners** | `ChannelPartnerController` | Channel partner integrations |
| **Charity** | `CharityContributionController` | Charity round contributions |
| **Punch Cards** | *(via CourseController or dedicated)* | Punch card management |
| **Club Portal** | `ClubCustomerPortalSectionsController`, `ClubMemberPortalSectionsController`, `ClubMobileAppSectionsController` | Portal section configuration |
| **Voucher Types** | `ClubVoucherTypeController` | Voucher type configuration |
| **Jonas Export** | `JonasExportsController` | Jonas ERP export |

---

## GolferWebAPI — Customer/Mobile REST API

**Base URL**: `{course-server}/GolferWebAPI`  
**Auth**: Token-based (BaseApiController)  
**Consumer clients**: cc_api_manager, cc_membership_portal, cc_ios, cc_android

### Controller Domains

| Domain | Controllers | Purpose |
|---|---|---|
| **Tee Times** | `TeeTimesV2Controller`, `TeeTimesV3Controller`, `TeeBookingController`, `TeeGroupBookingController`, `TeeSheetController` | Customer tee time search, booking, group booking |
| **Reservations** | `Reservation/ReservationController`, `CustomerReservationsController`, `CustomerTeeTimesController`, `ReservationRateOverrideRuleController` | Reservation management |
| **Memberships** | `Membership/MembershipController`, `Membership/MembershipPlanController`, `Membership/MembershipInvoiceController`, `Membership/MembershipLedgerController`, `Membership/MembershipPaymentController`, `Membership/MembershipGroupController`, `Membership/MembershipAutoPaySettingController`, `Membership/MembershipApplicationController`, `Membership/MemberRegistrationController`, `Membership/MembershipAutoPaySettingController` | Member-facing membership |
| **Vouchers** | `Membership/CreditVoucherController`, `VoucherSellController` | Voucher lookup, sale |
| **Wallet** | `Membership/CustomerWalletController` | Stored payment methods |
| **Membership Sale** | `MembershipSale/MembershipSaleController`, `MembershipSale/MembershipSaleStrategy2Controller`, `MembershipSale/MembershipSaleStrategy3Controller` | Online membership purchase flows |
| **Customer** | `CustomerController`, `GolferController`, `FriendsController`, `FavoriteController` | Customer profile, golfer info, friends, favourites |
| **On-Demand** | `OnDemandController`, `OnlineOrderingController` | Tablet/QR ordering |
| **Orders** | `OrderController`, `SalesController` | Customer order management |
| **Events** | `EventsController`, `EventCalandarController`, `LeaguesController` | Event/calendar/league |
| **Punch Cards** | `CustomerPunchCardsController` | Punch card balance/usage |
| **Promo Codes** | `PromoCodeController` | Promo code validation |
| **Inventory** | `InventoryController` | Product browsing |
| **Notifications** | `UserMobileDevicesController`, `MessagesController` | Device registration, push messages |
| **Statistics** | `StatisticsController` | Usage statistics |
| **Deposits** | `DepositController` | Deposit management |
| **File Storage** | `FileStorageController` | Azure blob file access |
| **Aggregators** | `AggregatorIntegration/TeeTimesController`, `AggregatorIntegration/CoursesController`, `AggregatorIntegration/CustomersController`, `AggregatorIntegration/MembersController`, `AggregatorIntegration/OrdersController`, `AggregatorIntegration/TeeBookingsController`, `AggregatorIntegration/ORCAReportsController` | Third-party aggregator APIs (Forefront, ORCA) |
| **CCInterface** | `CCInterface/V1/CCInterfaceCustomersController`, `CCInterface/V1/CCInterfaceProductsController`, `CCInterface/V1/CCInterfaceTeeSheetController`, `CCInterface/V1/CCInterfaceReflexBlueController` | Cross-club/multi-course integration |
| **MCO** | `MCOController` | Management Company Organization |
| **Mobile App Builder** | `MobileAppBuilder/MobileAppSectionController` | App section configuration |
| **Rangefinder** | `RangefinderController` | Rangefinder device integration |
| **Special Integrations** | `XGolfCustomerController`, `RedWaterCustomersController`, `PlayersFirstController` | Third-party golf platform integrations |
| **iFrame Banners** | `IFrameBannerController` | iFrame banner configuration |
| **Health** | `HealthCheck/HealthCheckEndpointController` | Health monitoring endpoint |
| **Bulletin Board** | `BulletinBoardController` | Customer-facing bulletin board |

---

## Internal APIs — GolflerShared (Shared Business Logic)

These are C# class interfaces consumed directly by PosApi and GolferWebAPI via the shared project.

| Class | Key Methods / Purpose |
|---|---|
| `Payment.cs` | Payment dispatch: `ProcessPayment()`, gateway routing logic |
| `TeeBooking.cs` | `BookTeeTime()`, `CancelTeeTime()`, availability checks |
| `Membership.cs` | `GetMembershipDetails()`, billing calculations |
| `Order.cs` | Order creation, modification, tax calculation |
| `CommonProperties.cs` (`WebSetting` class) | Setting name constants (e.g. `WebSetting.TaxInclusive`) — referenced throughout |

---

## Data Models — Key GF_ Tables

| Table | Purpose |
|---|---|
| `GF_Order` | All POS transactions |
| `GF_Customer` | Customer profiles (multi-tenant, CourseId required) |
| `GF_CourseInfo` | Per-course configuration and settings |
| `GF_Settings` | Key-value settings store (WebSetting constants map to column `SettingName`) |
| `GF_CreditVoucher` | Credit/gift voucher records |
| `GF_TeeSheet` | Tee time slot records |
| `GF_Membership` | Membership records |
| `GF_MembershipInvoice` | Membership billing invoices |
| `GF_MembershipLedger` | Membership payment ledger |
| `GF_Product` | Inventory products |
| `GF_Tax` | Tax configurations |
| `GF_Event` | Event records |

> Full schema: `stable-codebase\golfler_asp_2\docs\DATABASE.md` (88 KB)
