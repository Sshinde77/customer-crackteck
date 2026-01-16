# AMC Tab Integration - Bottom Navigation Update

## Overview
This document describes the changes made to replace the "Chat" tab with an "AMC" tab in the bottom navigation and integrate the AMC Plans screen.

## Changes Made

### 1. **Main App Provider Setup** (`lib/main.dart`)

**Added Import:**
```dart
import 'provider/amc_plan_provider.dart';
```

**Registered AmcPlanProvider:**
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => DocumentProvider()),
    ChangeNotifierProvider(create: (_) => CompanyProvider()),
    ChangeNotifierProvider(create: (_) => BannerProvider()),
    ChangeNotifierProvider(create: (_) => QuickServiceProvider()),
    ChangeNotifierProvider(create: (_) => AmcPlanProvider()), // ✅ Added
  ],
  child: const CrackCustomerTechApp(),
)
```

**Why This is Required:**
- The `AmcPlansScreen` uses `Consumer<AmcPlanProvider>` to access AMC plan data
- Without registering the provider in the widget tree, the app will throw:
  ```
  Could not find the correct Provider <AmcPlanProvider> above this Widget
  ```
- The provider must be registered at the app level (in `main.dart`) so it's available throughout the app

---

### 2. **CustomBottomNavBar Widget** (`lib/widgets/custom_bottom_nav.dart`)

**Changed:**
- Tab label: "Chat" → "AMC"
- Tab icon: `Icons.chat_bubble_outline` → `Icons.shield_outlined`
- Tab position: Index 1 (second tab, between Home and Product)

**Code Change:**
```dart
// Before
_buildNavItem(1, Icons.chat_bubble_outline, 'Chat'),

// After
_buildNavItem(1, Icons.shield_outlined, 'AMC'),
```

**Icon Choice:**
- `Icons.shield_outlined` - Represents protection and maintenance contracts (AMC)
- Alternative icons that could be used:
  - `Icons.security` - Security/protection theme
  - `Icons.verified_user_outlined` - User protection
  - `Icons.health_and_safety_outlined` - Safety/maintenance

---

### 3. **DashboardScreen** (`lib/screens/dashboard_screen.dart`)

**Added Import:**
```dart
import 'amc_plans_screen.dart';
```

**Updated Pages List:**
```dart
// Before
final List<Widget> _pages = [
  const HomeScreen(),           // Home Tab
  const Center(child: Text('Coming soon')),  // Chat Tab (placeholder)
  const ProductScreen(),        // Product Tab
  const ProfileScreen(),        // Profile Tab
];

// After
final List<Widget> _pages = [
  const HomeScreen(),           // Home Tab
  const AmcPlansScreen(),       // AMC Tab
  const ProductScreen(),        // Product Tab
  const ProfileScreen(),        // Profile Tab
];
```

---

## Bottom Navigation Structure

The bottom navigation now has the following tabs:

| Index | Icon | Label | Screen |
|-------|------|-------|--------|
| 0 | `home_outlined` | Home | `HomeScreen` |
| 1 | `shield_outlined` | **AMC** | **`AmcPlansScreen`** |
| 2 | `shopping_cart_outlined` | Product | `ProductScreen` |
| 3 | `person_outline` | Profile | `ProfileScreen` |

---

## Features

### AMC Tab Functionality
When users tap the AMC tab (index 1), they will see:
- ✅ List of all available AMC plans
- ✅ Plan cards with pricing, duration, and visit information
- ✅ Tap on any plan to view detailed information
- ✅ Pull-to-refresh functionality
- ✅ Error handling with retry option
- ✅ Loading states

### Navigation Flow
```
Dashboard (Bottom Nav)
    ↓ (Tap AMC Tab)
AmcPlansScreen
    ↓ (Tap Plan Card)
AmcPlanDetailScreen
```

---

## State Management

The `IndexedStack` widget in `DashboardScreen` ensures:
- ✅ Each tab's state is preserved when switching between tabs
- ✅ AMC Plans screen doesn't reload when navigating away and back
- ✅ Smooth tab switching without rebuilding screens

---

## Testing

To test the AMC tab integration:

1. **Run the app:**
   ```bash
   flutter run
   ```

2. **Navigate to Dashboard:**
   - Login with customer credentials (role_id: 4)
   - You should see the dashboard with 4 tabs

3. **Test AMC Tab:**
   - Tap the AMC tab (second tab with shield icon)
   - Verify AMC Plans screen loads
   - Verify plans are fetched from API
   - Tap on a plan to view details

4. **Test Tab Switching:**
   - Switch between tabs (Home → AMC → Product → Profile)
   - Verify AMC tab state is preserved
   - Verify no unnecessary reloads

5. **Test Error Handling:**
   - Turn off internet
   - Tap AMC tab
   - Verify error message displays
   - Tap retry button
   - Turn on internet
   - Verify plans load successfully

---

## Visual Design

### Active Tab (Selected)
- Background: Primary color (`AppColors.primary`)
- Icon: White, 24px
- Label: White, 12px, bold (w600)
- Shape: Rounded rectangle (12px radius)
- Padding: 16px horizontal, 8px vertical

### Inactive Tab
- Background: Transparent
- Icon: Grey, 24px
- Label: Grey, 12px, normal weight
- No background shape

---

## Files Modified

1. ✅ `lib/main.dart`
   - Added import for `AmcPlanProvider`
   - Registered `AmcPlanProvider` in `MultiProvider`

2. ✅ `lib/widgets/custom_bottom_nav.dart`
   - Changed tab icon and label

3. ✅ `lib/screens/dashboard_screen.dart`
   - Added import for `AmcPlansScreen`
   - Replaced placeholder with `AmcPlansScreen`

---

## Related Files

These files work together for the AMC functionality:

- `lib/screens/amc_plans_screen.dart` - AMC plans list screen
- `lib/screens/amc_plan_detail_screen.dart` - Plan detail screen
- `lib/provider/amc_plan_provider.dart` - State management
- `lib/models/amc_plan_model.dart` - Data models
- `lib/services/api_service.dart` - API calls
- `lib/constants/api_constants.dart` - API endpoints

---

## Notes

- The AMC tab is positioned at index 1 (second position) as requested
- The shield icon (`Icons.shield_outlined`) was chosen to represent protection/maintenance
- The existing tab functionality and navigation behavior is maintained
- No breaking changes to other tabs or screens
- The integration follows the existing app architecture and patterns

---

## Future Enhancements

Potential improvements for the AMC tab:

- [ ] Add badge notification for new/expiring AMC plans
- [ ] Add filter/sort options in AMC Plans screen
- [ ] Add search functionality for plans
- [ ] Add "My AMC Plans" section for subscribed plans
- [ ] Add renewal reminders
- [ ] Add plan comparison feature

