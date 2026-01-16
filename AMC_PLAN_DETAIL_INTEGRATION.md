# AMC Plan Detail API Integration

## Overview
This document describes the integration of the AMC Plan Detail API endpoint into the Flutter application.

## API Endpoint
```
GET https://crackteck.co.in/api/v1/amc-plan-details/{plan_id}?role_id=4
```

## Files Modified/Created

### 1. **API Constants** (`lib/constants/api_constants.dart`)
Added new endpoint constant:
```dart
static const String amcPlanDetails = '$baseUrl/amc-plan-details';
```

### 2. **Data Models** (`lib/models/amc_plan_model.dart`)
Added new response model for plan details:
```dart
class AmcPlanDetailResponse {
  final AmcPlan? amcPlan;
  final List<CoveredItem>? coveredItems;
  
  AmcPlanDetailResponse({this.amcPlan, this.coveredItems});
  
  factory AmcPlanDetailResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    
    return AmcPlanDetailResponse(
      amcPlan: data?['amc_plan'] != null 
          ? AmcPlan.fromJson(data!['amc_plan']) 
          : null,
      coveredItems: data?['covered_items'] != null
          ? (data!['covered_items'] as List)
                .map((i) => CoveredItem.fromJson(i))
                .toList()
          : null,
    );
  }
}
```

### 3. **API Service** (`lib/services/api_service.dart`)
Added new method to fetch plan details:
```dart
Future<ApiResponse<AmcPlanDetailResponse>> getAmcPlanDetails({
  required int planId,
  required int roleId,
}) async {
  // Implementation with full error handling
}
```

**Features:**
- ✅ Authenticated API calls with automatic token refresh
- ✅ Comprehensive error handling (SocketException, TimeoutException)
- ✅ HTML response detection
- ✅ Debug logging for request/response tracking

### 4. **Provider** (`lib/provider/amc_plan_provider.dart`)
Enhanced provider with plan detail management:

**New Properties:**
```dart
AmcPlanDetailResponse? _planDetail;
bool _isLoadingDetail = false;
String? _detailErrorMessage;
```

**New Methods:**
```dart
// Fetch plan details by ID
Future<void> fetchAmcPlanDetails({required int planId})

// Clear detail error message
void clearDetailError()

// Clear plan detail data
void clearPlanDetail()
```

### 5. **Detail Screen** (`lib/screens/amc_plan_detail_screen.dart`)
Created comprehensive detail screen with:

**Features:**
- ✅ Beautiful gradient header with plan name and status
- ✅ Detailed pricing breakdown (Plan Cost, Tax, Total)
- ✅ Payment terms display
- ✅ Plan information (Duration, Visits, Support Type)
- ✅ Covered services list with diagnosis tags
- ✅ Subscribe button with confirmation dialog
- ✅ Brochure and T&C download buttons (when available)
- ✅ Pull-to-refresh functionality
- ✅ Error handling with retry option
- ✅ Loading states
- ✅ Auto-cleanup on screen disposal

**UI Components:**
- Plan header card with gradient background
- Pricing details card
- Plan information card with icon boxes
- Service cards with diagnosis chips
- Action buttons (Subscribe, Brochure, T&C)

### 6. **Plans List Screen** (`lib/screens/amc_plans_screen.dart`)
Updated to navigate to detail screen:
- Removed modal bottom sheet implementation
- Added navigation to `AmcPlanDetailScreen` on card tap
- Added navigation on "View Details" button click

## Usage Examples

### 1. Direct API Call
```dart
final response = await ApiService.instance.getAmcPlanDetails(
  planId: 1,
  roleId: 4,
);

if (response.success) {
  final planDetail = response.data;
  print('Plan: ${planDetail?.amcPlan?.planName}');
  print('Services: ${planDetail?.coveredItems?.length}');
}
```

### 2. Using Provider
```dart
// Fetch plan details
context.read<AmcPlanProvider>().fetchAmcPlanDetails(planId: 1);

// Access data
final provider = context.watch<AmcPlanProvider>();
if (provider.isLoadingDetail) {
  // Show loading
} else if (provider.detailErrorMessage != null) {
  // Show error
} else {
  final planDetail = provider.planDetail;
  // Use plan detail data
}
```

### 3. Navigate to Detail Screen
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => AmcPlanDetailScreen(planId: 1),
  ),
);
```

## JSON Response Structure
```json
{
  "data": {
    "amc_plan": {
      "id": 1,
      "plan_name": "Basic AMC Plan",
      "plan_code": "AMCP-BASIC",
      "description": "Basic annual AMC covering essential services.",
      "duration": 12,
      "total_visits": 2,
      "plan_cost": "4999.00",
      "tax": "899.82",
      "total_cost": "5898.82",
      "pay_terms": "full_payment",
      "support_type": "onsite",
      "status": "active"
    },
    "covered_items": [
      {
        "id": 1,
        "item_code": "AMC-000001",
        "service_name": "Comprehensive AMC",
        "service_charge": "4999.00",
        "status": "active",
        "diagnosis_list": ["Cleaning", "Inspection", "Software Check"]
      }
    ]
  }
}
```

## Testing
To test the integration:

1. **Run the app:**
   ```bash
   flutter run
   ```

2. **Navigate to AMC Plans screen**

3. **Tap on any plan card** or click "View Details" button

4. **Verify:**
   - Plan details load correctly
   - All pricing information displays
   - Covered services show with diagnosis tags
   - Pull-to-refresh works
   - Error handling works (test with invalid plan ID)

## Next Steps
- [ ] Implement subscription/purchase functionality
- [ ] Add brochure download feature
- [ ] Add T&C viewer
- [ ] Add share functionality
- [ ] Add plan comparison feature
- [ ] Add favorites/bookmarking

## Notes
- The detail screen automatically clears data on disposal to prevent stale data
- All API calls include proper authentication headers
- Error messages are user-friendly and actionable
- The UI follows the app's design system (AppColors, consistent spacing)

