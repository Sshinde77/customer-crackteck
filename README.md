# customer-crackteck

## Project Overview
`customer-crackteck` is a Flutter mobile app for customer-side service management on Crackteck. The implemented flows include OTP-based login, product browsing and purchase, service request submission, AMC plan browsing, profile/document management, order history, and feedback viewing/submission.

### Target Users (from code)
- Primary: `Customer` (role_id `4` is hardcoded/default in many modules)
- Partially referenced but not fully implemented in this codebase: `Admin`, `Resident`, `Salesperson`, `Field Executive`

## UI Modules Documentation
Status labels are based on current code implementation only (not runtime verification).

| Module | Screen file(s) | Purpose | Navigation flow | Current status | TODO / incomplete logic |
|---|---|---|---|---|---|
| Login | `lib/login.dart` | Enter phone and request OTP | App start -> Login -> OTP; Login -> Sign Up | Working | None found |
| Sign Up | `lib/signup_screen.dart` | Customer signup form and registration | Login -> Sign Up -> Login (on success) | Working | Role is hardcoded to customer (`role_id: 4`) |
| OTP Verification | `lib/otp_screen.dart` | Verify OTP, resend OTP, role-based redirect | Login -> OTP -> Home/Admin/Resident/Sales dashboards | Under Development | Legacy commented OTP implementation kept in same file; role 1/2/3 destinations are not routed in `route_generator.dart`; `case 3` lacks `break` before `case 4` |
| Dashboard (Tab Shell) | `lib/screens/dashboard_screen.dart` | Bottom-tab container for Home/AMC/Product/Profile | OTP(role 4) -> Dashboard tabs | Working | None found |
| Bottom Navigation (Legacy) | `lib/screens/bottom_navigation.dart` | Older tab shell variant | Not routed from app routes | Not Started | Product/Profile tabs are placeholders (`Center(Text(...))`) |
| Home | `lib/screens/hometab.dart` | Show quick services, categories, banners, enquiry entry | Dashboard(Home tab) -> Notification / Service Enquiry / Product List / Quick Service Details | Working | Product category API uses hardcoded role `4`; quick-service card images are static assets |
| Service Enquiry | `lib/screens/service_enquiry.dart` | Choose service request type (installation/repair/AMC/quick) | Home -> Service Enquiry -> Service Request | Working | Service cards are static list (`Placeholder Service Card` comment) |
| Quick Service Details | `lib/screens/quick_service_details.dart` | Quick-service request form (products, images, address) | Home quick service -> Quick Service Details -> Service Detail / Address / Payment | Working | Uses fallback static copy and defaults when API values missing |
| Service Request | `lib/screens/service_request_screen.dart` | Generic service request form for enquiry and AMC | Service Enquiry or AMC Detail -> Service Request -> Service Detail / Address / Payment | Working | Service type derived from title string; HSN sent empty |
| Service Detail | `lib/screens/service_detail_screen.dart` | Display service details and diagnosis list | Quick Service Details/Service Request -> Service Detail | Under Development | Calls `getServiceRequestDetails` using `service.id` as `requestId` (can mismatch depending on payload) |
| AMC Plans | `lib/screens/amc_plans_screen.dart` | List AMC plans | Dashboard(AMC tab) -> AMC Plan Detail | Working | None found |
| AMC Plan Detail | `lib/screens/amc_plan_detail_screen.dart` | Show AMC plan details and subscribe flow | AMC Plans -> AMC Plan Detail -> AMC Service Request | Under Development | TODOs: share, brochure download, T&C viewer |
| Product List | `lib/screens/product_list.dart` | Product catalog, search, category filter | Dashboard(Product tab) or Home Quick Add -> Product Detail | Working | Uses hardcoded role `4` for product/category fetch |
| Product Detail | `lib/screens/product_detail_screen.dart` | Product details with quantity and buy-now action | Product List -> Product Detail -> Payment | Working | Uses hardcoded role `4` for detail fetch |
| Payment | `lib/screens/payment_screen.dart` | Select payment method and place order for product flow | Product Detail / Service Request / Quick Service -> Payment -> Home | Under Development | Offer code input has no apply logic; Add UPI action empty; payment options are static UI entries |
| Profile | `lib/screens/profile_screen.dart` | Profile summary and navigation hub | Dashboard(Profile tab) -> Personal Info / Orders / Service Requests / Quotation / Feedback / Logout | Under Development | Help & Support and Privacy policy entries have no handlers; Work Progress option commented out |
| Personal Information Hub | `lib/screens/personal_info_screen.dart` | Entry point for personal/address/docs/company screens | Profile -> Personal Info -> Personal Detail / Address / Documents / Company | Working | None found |
| Personal Detail | `lib/screens/personal_detail_screen.dart` | View/edit personal profile fields | Personal Info -> Personal Detail | Working | None found |
| Address Management | `lib/screens/address_screen.dart` | List/add/edit addresses | Personal Info or Payment/Service forms -> Address | Under Development | TODO: delete API integration missing |
| Documents | `lib/screens/documents_screen.dart` | View Aadhar/PAN and open edit screen | Personal Info -> Documents -> Edit Document | Working | Uses placeholder image URL when document image missing |
| Edit Document | `lib/screens/edit_document_screen.dart` | Upload/update Aadhar or PAN details/images | Documents -> Edit Document -> back with refresh | Working | None found |
| Company Details | `lib/screens/company_screen.dart` | View/edit company and GST details | Personal Info -> Company | Working | None found |
| My Product Orders | `lib/screens/my_product_orders_screen.dart` | List customer orders | Profile -> My Product Orders -> Order Detail | Working | None found |
| Order Detail | `lib/screens/order_detail_screen.dart` | Show selected order item and totals | My Product Orders -> Order Detail | Working | None found |
| My Service Requests | `lib/screens/my_service_request_screen.dart` | List done/pending service requests | Profile -> My Service Request -> Service Request Details | Under Development | Calendar FAB action empty; Give Feedback button action empty |
| Service Request Details | `lib/screens/service_request_details_screen.dart` | Show detailed service/product cards for request | My Service Request -> Service Request Details -> Work Progress Tracker | Working | None found |
| Work Progress Tracker | `lib/screens/work_progress_tracker_screen.dart` | Show diagnostics timeline | Service Request Details -> Work Progress Tracker | Under Development | Field executive card is static; call button action empty |
| Feedback List | `lib/screens/feedback_screen.dart` | List all feedback items | Profile -> Feedback -> Feedback Detail | Working | None found |
| Feedback Detail | `lib/screens/feedback_detail_screen.dart` | Show specific feedback details | Feedback List -> Feedback Detail | Working | None found |
| Give Feedback | `lib/screens/give_feedback_screen.dart` | Submit rating and comments | Intended from service request flow | Under Development | Screen exists but no active navigation path to open it |
| Notification | `lib/screens/notification.dart` | Notification list UI | Home bell -> Notification | Under Development | Static notification data; no backend integration |
| Quotation | `lib/screens/quotation_screen.dart` | Quotation summary UI | Profile -> Quotation | Under Development | Static hardcoded quotation data; Approve/Download actions empty |
| Coming Soon Placeholder | `lib/widgets/placeholder.dart` | Generic placeholder screen | Not wired to app routes | Not Started | Pure placeholder only |

## API Integration Documentation
All endpoints are from `lib/constants/api_constants.dart` and implementation is in `lib/services/api_service.dart` unless noted.

### Auth APIs
| API endpoint | Method | Request params/body | Response usage in UI | Used by screen/module | Integration status |
|---|---|---|---|---|---|
| `/send-otp` | POST | JSON body: `role_id`, `phone_number` | Success routes user to OTP screen | Login | Fully integrated & working |
| `/verify-otp` | POST | JSON body: `role_id`, `phone_number`, `otp` | Saves tokens/user context; navigates by role | OTP Verification | Fully integrated & working |
| `/refresh-token` | POST | Query: `user_id`, `role_id`; body includes `role_id`; bearer token header | Used in authenticated retry middleware | ApiService internal auth wrapper | Fully integrated & working |
| `/signup` | POST (multipart) | Fields: `first_name`, `last_name`, `phone`, `email`, `gender`, `role_id` | Shows signup result and redirects to login | Sign Up | Fully integrated & working |
| `/logout` | POST | Query: `user_id`, `role_id`; bearer token header | Clears session and returns to login | Profile | Fully integrated & working |

### Profile, Address, Document, Company APIs
| API endpoint | Method | Request params/body | Response usage in UI | Used by screen/module | Integration status |
|---|---|---|---|---|---|
| `/profile` | GET | Query: `user_id`, `role_id` | Populates user profile data | Profile, Personal Detail | Fully integrated & working |
| `/profile` | PUT | JSON body: `user_id`, `role_id`, `first_name`, `last_name`, `email`, `dob`, `gender` | Saves edited profile | Personal Detail | Fully integrated & working |
| `/addresses` | GET | Query: `user_id`, `role_id` | Address dropdown/list population | Address, Payment, Service Request, Quick Service Details | Fully integrated & working |
| `/address` | POST | Query includes address fields (`branch_name`, `address1`, `city`, etc.) | Adds new address and refreshes list | Address | Fully integrated & working |
| `/address/{addressId}` | PUT | Query: `user_id`, `role_id`; JSON body with address fields | Updates existing address | Address | Fully integrated & working |
| `/aadhar-card` | GET | Query: `user_id`, `role_id` | Shows Aadhar number/images | Documents (`DocumentProvider`) | Fully integrated & working |
| `/aadhar-card` or `/aadhar-card/{id}` | POST (multipart; `_method=PUT` for update) | Fields: `user_id`, `role_id`, `aadhar_number`, optional image files | Adds/updates Aadhar | Edit Document | Fully integrated & working |
| `/customer-pan-card` | GET | Query: `user_id`, `role_id` | Shows PAN number/images | Documents (`DocumentProvider`) | Fully integrated & working |
| `/customer-pan-card` or `/customer-pan-card/{id}` | POST (multipart; `_method=PUT` for update) | Fields: `user_id`, `role_id`, `pan_number`, optional image files | Adds/updates PAN | Edit Document | Fully integrated & working |
| `/company-details` | GET | Query: `user_id`, `role_id` | Displays stored company info | Company (`CompanyProvider`) | Fully integrated & working |
| `/company-details` | POST | JSON body with company fields + user/role IDs | Creates company details | Company (`CompanyProvider`) | Fully integrated & working |
| `/company-details/{companyId}` | PUT | Query params with company fields + user/role IDs | Updates existing company details | Company (`CompanyProvider`) | Fully integrated & working |

### Home, Product, Orders APIs
| API endpoint | Method | Request params/body | Response usage in UI | Used by screen/module | Integration status |
|---|---|---|---|---|---|
| `/banners` | GET | Query: `role_id` | Home banner slider | Home (`BannerProvider`) | Fully integrated & working |
| `/product/categories` | GET | Query: `role_id` | Category chips/dropdowns for home and products | Home, Product List | Fully integrated & working |
| `/product` | GET | Query: `role_id` | Product catalog list/grid | Product List | Fully integrated & working |
| `/product/{productId}` | GET | Query: `role_id` | Product detail content | Product Detail | Fully integrated & working |
| `/buy-product/{productId}` | POST | Query: `role_id`, `quantity`, `customer_id`, `shipping_address_id`; body includes `shipping_address_id` | Purchase confirmation and redirect | Payment | Fully integrated & working |
| `/order` | GET | Query: `role_id`, `customer_id` | Order list and order detail selection | My Product Orders, Order Detail | Fully integrated & working |

### Service Request APIs
| API endpoint | Method | Request params/body | Response usage in UI | Used by screen/module | Integration status |
|---|---|---|---|---|---|
| `/quick-services` | GET | Query: `role_id` | ApiService method exists but no UI callsite | ApiService only (`getQuickServices`) | Integrated but UI pending |
| `/services-list` | GET | Query: `role_id`, `service_type` | Populates quick-service/service-type lists | Home, Service Request (`QuickServiceProvider`) | Fully integrated & working |
| `/submit-quick-service-request` | POST (multipart) | Fields: `customer_id`, `role_id`, `service_type`, `customer_address_id`, optional `amc_plan_id`, nested product fields/images | Submit request and proceed to payment | Quick Service Details, Service Request | Fully integrated & working |
| `/all-service-requests` | GET | Query: `role_id`, `customer_id` | Done/pending list cards | My Service Request | Fully integrated & working |
| `/service-request-details/{requestId}` | GET | Query: `role_id`, `customer_id` | Service detail cards and service detail panel | Service Request Details, Service Detail | Fully integrated & working |
| `/service-request-product-diagnostics/{requestId}/{serviceProductId}` | GET | Query: `role_id`, `customer_id` | Diagnostics timeline | Work Progress Tracker | Fully integrated & working |
| `/services` | (not implemented) | No method implementation in service layer | No UI usage | None | Not integrated |

### Feedback APIs
| API endpoint | Method | Request params/body | Response usage in UI | Used by screen/module | Integration status |
|---|---|---|---|---|---|
| `/give-feedback` | POST | Query: `role_id`, `customer_id`, `service_type`, `service_id`, `rating`, `comments`; empty JSON body | Submit feedback form result | Give Feedback screen | Integrated but UI pending |
| `/get-feedback/{feedbackId}` | GET | Query: `role_id`, `customer_id` | Feedback detail page data | Feedback Detail | Fully integrated & working |
| `/get-all-feedback` | GET | Query: `role_id`, `customer_id` | Feedback list cards | Feedback | Fully integrated & working |

### AMC APIs
| API endpoint | Method | Request params/body | Response usage in UI | Used by screen/module | Integration status |
|---|---|---|---|---|---|
| `/amc-plans` | GET | Query: `role_id` | AMC plans list UI | AMC Plans (`AmcPlanProvider`) | Fully integrated & working |
| `/amc-plan-details/{planId}` | GET | Query: `role_id` | AMC plan detail UI | AMC Plan Detail (`AmcPlanProvider`) | Fully integrated & working |

## Module vs API Mapping

### API-dependent UI modules
| UI module | API dependencies |
|---|---|
| Login | `/send-otp` |
| OTP Verification | `/verify-otp`, `/send-otp` (resend) |
| Sign Up | `/signup` |
| Home | `/banners`, `/services-list`, `/product/categories` |
| Product List | `/product/categories`, `/product` |
| Product Detail | `/product/{id}` |
| Payment | `/buy-product/{id}`, `/addresses` |
| Profile | `/profile` (GET), `/logout` |
| Personal Detail | `/profile` (GET, PUT) |
| Address | `/addresses`, `/address`, `/address/{id}` |
| Documents | `/aadhar-card`, `/customer-pan-card` (GET via `DocumentProvider`) |
| Edit Document | `/aadhar-card` (POST/PUT multipart), `/customer-pan-card` (POST/PUT multipart) |
| Company | `/company-details` (GET/POST/PUT) |
| My Product Orders | `/order` |
| Order Detail | `/order` (via `getOrderDetail`) |
| Service Request | `/services-list`, `/submit-quick-service-request`, `/addresses` |
| Quick Service Details | `/submit-quick-service-request`, `/addresses` |
| My Service Request | `/all-service-requests` |
| Service Request Details | `/service-request-details/{id}` |
| Service Detail | `/service-request-details/{id}` |
| Work Progress Tracker | `/service-request-product-diagnostics/{requestId}/{serviceProductId}` |
| Feedback | `/get-all-feedback` |
| Feedback Detail | `/get-feedback/{id}` |
| Give Feedback | `/give-feedback` |
| AMC Plans | `/amc-plans` |
| AMC Plan Detail | `/amc-plan-details/{id}` |

### UI-complete but API-incomplete (or no backend wiring)
- Notification: fully static cards, no API.
- Quotation: fully static quotation content, no API.
- Legacy BottomNavigation screen: placeholder tabs, not route-wired.

### API-integrated but UI-pending
- `/quick-services`: service method exists (`getQuickServices`) but no UI currently consumes it.
- `/give-feedback`: screen and API exist, but no active navigation path to open `GiveFeedbackScreen`.
- `/services`: constant exists but no service-layer method or UI usage.

## Known Issues & Gaps

### Missing buttons / empty actions
- `lib/screens/my_service_request_screen.dart`: calendar FAB action is empty.
- `lib/screens/my_service_request_screen.dart`: `Give Feedback` button action is empty.
- `lib/screens/payment_screen.dart`: `Add New UPI ID` action is empty.
- `lib/screens/quotation_screen.dart`: `Approve` and `Download` button actions are empty.
- `lib/screens/work_progress_tracker_screen.dart`: call icon button action is empty.

### Incomplete flows
- OTP role routing:
  - Routes for admin/resident/salesperson are referenced in OTP but not handled in `lib/routes/route_generator.dart`.
  - `case 3` in OTP switch has no `break`, so flow can fall through to customer home.
- My Service Request to Give Feedback flow is not connected (button is present but not wired).

### Hardcoded values
- Role is defaulted/hardcoded to customer (`role_id = 4`) in multiple places (`AppStrings.roleId`, signup payload, product/category fetches).
- Quotation screen is hardcoded demo content (`Lead ID`, `Quotation ID`, customer name, totals).
- Notification screen uses hardcoded sample notifications.
- Work Progress Tracker uses hardcoded field executive avatar/name text.
- Secure storage is in-memory only (`lib/constants/core/secure_storage_service.dart`), so tokens/session data are not persisted across app restarts.

### TODO/FIXME markers found
- `lib/screens/address_screen.dart`: `TODO: Integrate delete API`
- `lib/screens/amc_plan_detail_screen.dart`: `TODO: Implement share functionality`
- `lib/screens/amc_plan_detail_screen.dart`: `TODO: Download brochure`
- `lib/screens/amc_plan_detail_screen.dart`: `TODO: View terms and conditions`

## Summary Table

| Metric | Count |
|---|---:|
| Total UI modules/screens found | 33 |
| Working modules | 20 |
| Modules under development | 11 |
| Not started modules | 2 |
| Total API endpoints defined | 29 |
| Working APIs (fully integrated) | 26 |
| APIs pending integration | 3 |

### Pending API breakdown
- Integrated but UI pending: 2 (`/quick-services`, `/give-feedback`)
- Not integrated: 1 (`/services`)



storePassword=crackteck789
keyPassword=crackteck789
keyAlias=crackteck_upload
storeFile=app/upload-keystore.jks


SHA1: 20:79:3C:DA:F7:21:E6:23:9D:B6:71:44:88:99:1B:F6:3C:11:84:59
SHA-256: 93:5A:C2:02:3C:9F:82:F2:97:16:A1:DE:EB:1C:ED:89:AF:1F:5A:7C:4B:A9:A6:F0:81:AB:DA:01:49:CF:4F:0F