# AMC Plan Subscribe Navigation Implementation

## Overview
This document describes the implementation of navigation from the AMC Plan Detail screen to the AMC Service Request screen when users click the "Subscribe to Plan" button.

---

## Changes Made

### 1. **AmcPlanDetailScreen** (`lib/screens/amc_plan_detail_screen.dart`)

#### Added Import
```dart
import 'service_request_screen.dart';
```

#### Updated `_buildActionButtons` Method
**Before:**
```dart
onPressed: () {
  // TODO: Implement subscribe/purchase functionality
  _showSubscribeDialog();
},
```

**After:**
```dart
onPressed: () {
  // Navigate to AMC Service Request screen with plan data
  if (plan != null) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceRequestScreen(
          title: 'AMC Service Request',
          amcPlanData: {
            'planId': plan.id,
            'planName': plan.planName,
            'planCode': plan.planCode,
            'duration': plan.duration,
            'totalVisits': plan.totalVisits,
            'planCost': plan.planCost,
            'tax': plan.tax,
            'totalCost': plan.totalCost,
            'supportType': plan.supportType,
            'description': plan.description,
          },
        ),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Plan details not available'),
        backgroundColor: Colors.red,
      ),
    );
  }
},
```

#### Removed Unused Method
- Removed `_showSubscribeDialog()` method (no longer needed)

---

### 2. **ServiceRequestScreen** (`lib/screens/service_request_screen.dart`)

#### Updated Constructor
**Before:**
```dart
class ServiceRequestScreen extends StatefulWidget {
  final String title;

  const ServiceRequestScreen({super.key, required this.title});
}
```

**After:**
```dart
class ServiceRequestScreen extends StatefulWidget {
  final String title;
  final Map<String, dynamic>? amcPlanData;

  const ServiceRequestScreen({
    super.key,
    required this.title,
    this.amcPlanData,
  });
}
```

**Why This Change:**
- Added optional `amcPlanData` parameter to accept AMC plan information
- Allows the service request form to be pre-populated with plan details
- Maintains backward compatibility (parameter is optional)

---

## Navigation Flow

```
AMC Plans Screen (AmcPlansScreen)
    ↓ (Tap Plan Card)
AMC Plan Detail Screen (AmcPlanDetailScreen)
    ↓ (Tap "Subscribe to Plan" Button)
AMC Service Request Screen (ServiceRequestScreen)
    ↓ (Fill Form & Submit)
Payment Screen / Confirmation
```

---

## Data Passed to Service Request Screen

The following AMC plan data is passed as arguments:

| Key | Type | Description | Example |
|-----|------|-------------|---------|
| `planId` | `int?` | Unique plan identifier | `1` |
| `planName` | `String?` | Name of the AMC plan | `"Basic AMC Plan"` |
| `planCode` | `String?` | Plan code | `"AMC-001"` |
| `duration` | `int?` | Plan duration in months | `12` |
| `totalVisits` | `int?` | Number of visits included | `4` |
| `planCost` | `String?` | Base plan cost | `"5000"` |
| `tax` | `String?` | Tax amount | `"900"` |
| `totalCost` | `String?` | Total cost (plan + tax) | `"5900"` |
| `supportType` | `String?` | Type of support | `"onsite"` |
| `description` | `String?` | Plan description | `"Comprehensive AMC..."` |

---

## Usage Example

### Accessing AMC Plan Data in ServiceRequestScreen

```dart
@override
void initState() {
  super.initState();
  
  // Check if AMC plan data is available
  if (widget.amcPlanData != null) {
    final planName = widget.amcPlanData!['planName'];
    final totalCost = widget.amcPlanData!['totalCost'];
    
    // Pre-populate form fields or display plan info
    debugPrint('AMC Plan: $planName, Cost: ₹$totalCost');
  }
}
```

---

## Benefits

✅ **Seamless User Experience**
- Direct navigation from plan details to service request
- No intermediate dialogs or confirmations needed
- Users can immediately proceed with subscription

✅ **Data Continuity**
- Plan information is passed to the service request screen
- Can be used to pre-populate form fields
- Reduces user input and potential errors

✅ **Maintains Navigation Stack**
- Uses `Navigator.push()` instead of `pushReplacement()`
- Users can navigate back to plan details if needed
- Preserves app navigation history

✅ **Error Handling**
- Validates plan data before navigation
- Shows error message if plan details are unavailable
- Prevents navigation with incomplete data

---

## Testing

### Test Scenarios

1. **Happy Path:**
   - Navigate to AMC Plans screen
   - Tap on a plan card
   - View plan details
   - Tap "Subscribe to Plan" button
   - ✅ Should navigate to AMC Service Request screen
   - ✅ Plan data should be available in `amcPlanData`

2. **Error Handling:**
   - If plan data is null
   - ✅ Should show error snackbar
   - ✅ Should not navigate

3. **Back Navigation:**
   - From Service Request screen, tap back button
   - ✅ Should return to Plan Detail screen
   - ✅ Plan details should still be loaded

---

## Future Enhancements

Potential improvements for the service request flow:

- [ ] Pre-populate service request form with plan data
- [ ] Add plan summary card at the top of service request form
- [ ] Auto-select "AMC Service Request" in service type dropdown
- [ ] Display plan cost in the form
- [ ] Add plan terms and conditions link in the form
- [ ] Implement plan-specific validation rules
- [ ] Add plan discount/promo code support

---

## Files Modified

1. ✅ `lib/screens/amc_plan_detail_screen.dart`
   - Added import for `ServiceRequestScreen`
   - Updated `_buildActionButtons` to navigate with plan data
   - Removed unused `_showSubscribeDialog` method

2. ✅ `lib/screens/service_request_screen.dart`
   - Added optional `amcPlanData` parameter to constructor
   - Maintains backward compatibility

---

## Notes

- The navigation uses `MaterialPageRoute` for standard push navigation
- Plan data is passed as a `Map<String, dynamic>` for flexibility
- All plan fields are optional (nullable) to handle incomplete data
- The service request screen can still be used for non-AMC requests
- No breaking changes to existing service request functionality

