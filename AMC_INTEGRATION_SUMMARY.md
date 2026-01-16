# AMC Plans API Integration Summary

## Overview
Successfully integrated the AMC Plans API endpoint into the Flutter application.

## API Endpoint
- **URL**: `https://crackteck.co.in/api/v1/amc-plans?role_id=4`
- **Method**: GET
- **Authentication**: Bearer Token (handled automatically)

## Files Created/Modified

### 1. Model - `lib/models/amc_plan_model.dart`
Created comprehensive model classes to handle the AMC plans JSON response:
- `AmcPlanResponse` - Root response wrapper
- `AmcPlanItem` - Individual plan item containing plan and covered items
- `AmcPlan` - Plan details (id, name, code, description, duration, visits, costs, etc.)
- `CoveredItem` - Service items covered by the plan

All models include:
- `fromJson()` factory constructors for JSON deserialization
- `toJson()` methods for JSON serialization
- Proper null safety handling

### 2. API Constants - `lib/constants/api_constants.dart`
Added new endpoint constant:
```dart
static const String amcPlans = '$baseUrl/amc-plans';
```

### 3. API Service - `lib/services/api_service.dart`
Added new API method:
```dart
Future<ApiResponse<List<AmcPlanItem>>> getAmcPlans({required int roleId})
```

Features:
- Authenticated GET request with automatic token refresh
- Comprehensive error handling (network errors, timeouts, HTML responses)
- Debug logging for request/response tracking
- Returns `ApiResponse<List<AmcPlanItem>>` with success/error states

### 4. Provider - `lib/provider/amc_plan_provider.dart`
Created state management provider using ChangeNotifier pattern:
- `fetchAmcPlans()` - Fetches AMC plans from API
- `isLoading` - Loading state indicator
- `amcPlans` - List of fetched AMC plan items
- `errorMessage` - Error message if fetch fails
- `clearError()` - Clear error state

## Usage Example

### 1. Register Provider in main.dart
```dart
MultiProvider(
  providers: [
    // ... existing providers
    ChangeNotifierProvider(create: (_) => AmcPlanProvider()),
  ],
  child: const CrackCustomerTechApp(),
)
```

### 2. Use in a Screen
```dart
import 'package:provider/provider.dart';
import '../provider/amc_plan_provider.dart';

class AmcPlansScreen extends StatefulWidget {
  @override
  _AmcPlansScreenState createState() => _AmcPlansScreenState();
}

class _AmcPlansScreenState extends State<AmcPlansScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch AMC plans when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AmcPlanProvider>().fetchAmcPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AMC Plans')),
      body: Consumer<AmcPlanProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(child: Text('Error: ${provider.errorMessage}'));
          }

          if (provider.amcPlans.isEmpty) {
            return Center(child: Text('No AMC plans available'));
          }

          return ListView.builder(
            itemCount: provider.amcPlans.length,
            itemBuilder: (context, index) {
              final planItem = provider.amcPlans[index];
              final plan = planItem.plan;
              
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  title: Text(plan?.planName ?? 'N/A'),
                  subtitle: Text(plan?.description ?? ''),
                  trailing: Text('₹${plan?.totalCost ?? '0'}'),
                  onTap: () {
                    // Navigate to plan details
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

### 3. Direct API Call (without Provider)
```dart
import '../services/api_service.dart';
import '../constants/app_strings.dart';

Future<void> fetchAmcPlans() async {
  final response = await ApiService.instance.getAmcPlans(
    roleId: AppStrings.roleId, // or use 4 directly
  );

  if (response.success) {
    final plans = response.data; // List<AmcPlanItem>
    // Use the plans data
    for (var planItem in plans ?? []) {
      print('Plan: ${planItem.plan?.planName}');
      print('Cost: ${planItem.plan?.totalCost}');
      print('Covered Items: ${planItem.coveredItems?.length}');
    }
  } else {
    print('Error: ${response.message}');
  }
}
```

## Data Structure Example

```dart
AmcPlanItem {
  plan: AmcPlan {
    id: 1,
    planName: "Basic AMC Plan",
    planCode: "AMCP-BASIC",
    description: "Basic annual AMC covering essential services.",
    duration: 12,
    totalVisits: 2,
    planCost: "4999.00",
    tax: "899.82",
    totalCost: "5898.82",
    payTerms: "full_payment",
    supportType: "onsite",
    status: "active"
  },
  coveredItems: [
    CoveredItem {
      id: 1,
      itemCode: "AMC-000001",
      serviceType: "amc",
      serviceName: "Comprehensive AMC",
      serviceCharge: "4999.00",
      diagnosisList: ["Cleaning", "Inspection", "Software Check"]
    }
  ]
}
```

## Next Steps

1. **Register the Provider**: Add `AmcPlanProvider` to the MultiProvider in `main.dart`
2. **Create UI Screen**: Build a screen to display AMC plans
3. **Add Navigation**: Add route for AMC plans screen in `app_routes.dart` and `route_generator.dart`
4. **Testing**: Test the API integration with real data

## Notes
- The API uses the same authentication mechanism as other endpoints
- Automatic token refresh is handled by `_performAuthenticatedGet()`
- All network errors and timeouts are properly handled
- Debug logs are available for troubleshooting (look for 🔵 and 🟡 emojis in console)

