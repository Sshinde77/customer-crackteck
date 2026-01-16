# AMC Plans API - Quick Reference Guide

## 📋 Available APIs

### 1. Get All AMC Plans
**Endpoint:** `GET /api/v1/amc-plans?role_id=4`

**Usage:**
```dart
// Using Provider
context.read<AmcPlanProvider>().fetchAmcPlans();

// Direct API call
final response = await ApiService.instance.getAmcPlans(roleId: 4);
```

**Response:** List of `AmcPlanItem` objects

---

### 2. Get AMC Plan Details
**Endpoint:** `GET /api/v1/amc-plan-details/{plan_id}?role_id=4`

**Usage:**
```dart
// Using Provider
context.read<AmcPlanProvider>().fetchAmcPlanDetails(planId: 1);

// Direct API call
final response = await ApiService.instance.getAmcPlanDetails(
  planId: 1,
  roleId: 4,
);
```

**Response:** `AmcPlanDetailResponse` object

---

## 🎨 UI Screens

### AMC Plans List Screen
**File:** `lib/screens/amc_plans_screen.dart`

**Features:**
- Displays all available AMC plans
- Shows plan summary (name, price, duration, visits)
- Tap to view details
- Pull-to-refresh
- Error handling with retry

**Navigation:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const AmcPlansScreen(),
  ),
);
```

---

### AMC Plan Detail Screen
**File:** `lib/screens/amc_plan_detail_screen.dart`

**Features:**
- Complete plan information
- Pricing breakdown
- Covered services with diagnosis
- Subscribe button
- Brochure & T&C buttons
- Pull-to-refresh

**Navigation:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => AmcPlanDetailScreen(planId: 1),
  ),
);
```

---

## 📦 Data Models

### AmcPlan
Main plan information:
```dart
class AmcPlan {
  final int? id;
  final String? planName;
  final String? planCode;
  final String? description;
  final int? duration;           // in months
  final int? totalVisits;
  final String? planCost;
  final String? tax;
  final String? totalCost;
  final String? payTerms;        // e.g., "full_payment"
  final String? supportType;     // e.g., "onsite"
  final String? status;          // "active" or "inactive"
  final String? brochure;        // URL
  final String? tandc;           // URL
  final String? replacementPolicy; // URL
}
```

### CoveredItem
Service covered by the plan:
```dart
class CoveredItem {
  final int? id;
  final String? itemCode;
  final String? serviceType;
  final String? serviceName;
  final String? serviceCharge;
  final String? status;
  final List<String>? diagnosisList;
}
```

### AmcPlanItem (List Response)
```dart
class AmcPlanItem {
  final AmcPlan? plan;
  final List<CoveredItem>? coveredItems;
}
```

### AmcPlanDetailResponse (Detail Response)
```dart
class AmcPlanDetailResponse {
  final AmcPlan? amcPlan;
  final List<CoveredItem>? coveredItems;
}
```

---

## 🔧 Provider Methods

### AmcPlanProvider

**Fetch Plans:**
```dart
await context.read<AmcPlanProvider>().fetchAmcPlans();
```

**Fetch Plan Details:**
```dart
await context.read<AmcPlanProvider>().fetchAmcPlanDetails(planId: 1);
```

**Access Data:**
```dart
final provider = context.watch<AmcPlanProvider>();

// Plans list
List<AmcPlanItem> plans = provider.amcPlans;
bool isLoading = provider.isLoading;
String? error = provider.errorMessage;

// Plan detail
AmcPlanDetailResponse? detail = provider.planDetail;
bool isLoadingDetail = provider.isLoadingDetail;
String? detailError = provider.detailErrorMessage;
```

**Clear Methods:**
```dart
provider.clearError();          // Clear list error
provider.clearDetailError();    // Clear detail error
provider.clearPlanDetail();     // Clear detail data
```

---

## 🎯 Common Use Cases

### 1. Display Plans List
```dart
Consumer<AmcPlanProvider>(
  builder: (context, provider, child) {
    if (provider.isLoading) {
      return CircularProgressIndicator();
    }
    
    return ListView.builder(
      itemCount: provider.amcPlans.length,
      itemBuilder: (context, index) {
        final planItem = provider.amcPlans[index];
        return ListTile(
          title: Text(planItem.plan?.planName ?? ''),
          subtitle: Text('₹${planItem.plan?.totalCost ?? '0'}'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AmcPlanDetailScreen(
                  planId: planItem.plan!.id!,
                ),
              ),
            );
          },
        );
      },
    );
  },
)
```

### 2. Show Plan Details
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<AmcPlanProvider>().fetchAmcPlanDetails(
      planId: widget.planId,
    );
  });
}

@override
Widget build(BuildContext context) {
  return Consumer<AmcPlanProvider>(
    builder: (context, provider, child) {
      final detail = provider.planDetail;
      if (detail == null) return SizedBox();
      
      return Column(
        children: [
          Text(detail.amcPlan?.planName ?? ''),
          Text('₹${detail.amcPlan?.totalCost ?? '0'}'),
          // ... more widgets
        ],
      );
    },
  );
}
```

---

## ⚠️ Error Handling

All API calls return `ApiResponse<T>` with:
- `success`: Boolean indicating success/failure
- `message`: User-friendly error message
- `data`: Response data (if successful)
- `errors`: Validation errors (if any)

**Example:**
```dart
final response = await ApiService.instance.getAmcPlanDetails(
  planId: 1,
  roleId: 4,
);

if (response.success) {
  // Handle success
  final data = response.data;
} else {
  // Handle error
  print(response.message);
}
```

---

## 🔐 Authentication

All API calls automatically include:
- Bearer token from secure storage
- Automatic token refresh on 401 errors
- Proper error handling for authentication failures

No manual token management required!

---

## 📝 Notes

- Always use `roleId: 4` for customer role
- Plan IDs are integers
- Prices are strings (formatted as decimal)
- Status values: "active" or "inactive"
- Payment terms: "full_payment", "installment", etc.
- Support types: "onsite", "remote", etc.

