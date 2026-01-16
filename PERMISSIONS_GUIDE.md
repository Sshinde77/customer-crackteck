# App Permissions Configuration Guide (Minimal & App Store Compliant)

## Overview
This document describes the **minimal essential permissions** configured for the Customer CrackTech app on both Android and iOS platforms. All permissions are strictly necessary for core app functionality and comply with app store guidelines.

---

## ✅ Why Minimal Permissions?

**App Store Compliance:**
- Google Play Store and Apple App Store reject apps with excessive permissions
- Only request permissions that are essential for core functionality
- Provide clear justification for each permission
- Avoid sensitive permissions (SMS, Phone State, Location, Contacts, etc.) unless absolutely necessary

**User Trust:**
- Users are more likely to install apps with fewer permission requests
- Minimal permissions improve app ratings and reviews
- Reduces privacy concerns

---

## 📱 Android Permissions (7 Total)

### File: `android/app/src/main/AndroidManifest.xml`

#### 1. **Internet & Network Permissions** ✅ ESSENTIAL
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```
**Why Essential:**
- Required for all API calls to backend server
- Check network connectivity before making requests
- Core functionality: Login, data sync, service requests

**Used For:**
- Login/OTP verification
- Fetching AMC plans, products, banners
- Service requests and quotations
- Image uploads to server

---

#### 2. **Camera Permission** ✅ ESSENTIAL
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
```
**Why Essential:**
- Required for document verification (Aadhar, PAN card)
- Service request photo capture
- Camera marked as optional (app works on devices without camera)

**Used For:**
- Taking photos for service requests
- Document uploads (Aadhar, PAN card)
- Product/issue documentation

---

#### 3. **Storage/Media Permissions** ✅ ESSENTIAL
```xml
<!-- For Android 12 and below -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32" />

<!-- For Android 13+ (Granular media permissions) -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```
**Why Essential:**
- Required to select images from gallery
- Upload existing photos for documents
- Android 13+ uses granular permissions (images only, no videos)

**Used For:**
- Selecting images from gallery
- Uploading pre-existing documents
- Image picker functionality

---

#### 4. **Notification Permission** ✅ ESSENTIAL (Android 13+)
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```
**Why Essential:**
- Required for Android 13+ to show notifications
- Critical for user engagement and updates

**Used For:**
- Service request status updates
- Order notifications
- AMC plan reminders
- Important alerts

---

#### 5. **Vibration Permission** ✅ ESSENTIAL
```xml
<uses-permission android:name="android.permission.VIBRATE" />
```
**Why Essential:**
- Provides haptic feedback for notifications
- Improves user experience
- Low-risk permission

**Used For:**
- Notification vibration
- User interaction feedback

---

### ❌ Removed Permissions (Not Essential)

The following permissions were **REMOVED** to comply with app store guidelines:

| Permission | Reason for Removal |
|------------|-------------------|
| `ACCESS_WIFI_STATE` | Not essential; `ACCESS_NETWORK_STATE` is sufficient |
| `READ_MEDIA_VIDEO` | App doesn't use videos |
| `RECEIVE_SMS` | Sensitive; OTP can be entered manually |
| `READ_SMS` | Sensitive; not essential for core functionality |
| `SEND_SMS` | Not used in app |
| `AD_ID` | Not needed; no ads in app |
| `READ_PHONE_STATE` | Sensitive; not essential |
| `READ_PHONE_NUMBERS` | Sensitive; user can enter phone manually |
| `ACCESS_FINE_LOCATION` | Sensitive; not core functionality |
| `ACCESS_COARSE_LOCATION` | Sensitive; not core functionality |
| `WAKE_LOCK` | Not essential for app functionality |
| `FOREGROUND_SERVICE` | Not currently used |

---

## 🍎 iOS Permissions (2 Total)

### File: `ios/Runner/Info.plist`

#### 1. **Camera Permission** ✅ ESSENTIAL
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to capture photos of documents (Aadhar, PAN card) and service-related images for your requests.</string>
```
**Why Essential:**
- Required for document verification
- Service request photo capture
- Clear, specific usage description

---

#### 2. **Photo Library Permission** ✅ ESSENTIAL
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to let you select images for document uploads and service requests.</string>
```
**Why Essential:**
- Required to select existing photos
- Upload pre-captured documents
- Clear, specific usage description

---

#### 3. **App Transport Security** ✅ REQUIRED
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    <key>NSAllowsArbitraryLoadsInWebContent</key>
    <true/>
</dict>
```
**Why Required:**
- Allows HTTP connections to API server
- Required for API communication
- Should be restricted to specific domains in production

---

### ❌ Removed Permissions (Not Essential)

The following permissions were **REMOVED** to comply with app store guidelines:

| Permission | Reason for Removal |
|------------|-------------------|
| `NSPhotoLibraryAddUsageDescription` | App doesn't save photos to library |
| `NSMicrophoneUsageDescription` | No audio/video recording features |
| `NSLocationWhenInUseUsageDescription` | Not core functionality |
| `NSLocationAlwaysUsageDescription` | Sensitive; not needed |
| `NSLocationAlwaysAndWhenInUseUsageDescription` | Sensitive; not needed |
| `NSContactsUsageDescription` | Not used in app |
| `NSCalendarsUsageDescription` | Not used in app |
| `NSRemindersUsageDescription` | Not used in app |
| `NSMotionUsageDescription` | Not used in app |
| `NSSpeechRecognitionUsageDescription` | Not used in app |
| `NSBluetoothAlwaysUsageDescription` | Not used in app |
| `NSBluetoothPeripheralUsageDescription` | Not used in app |
| `NSLocalNetworkUsageDescription` | Not needed |
| `NSFaceIDUsageDescription` | Not implemented |

---

## 📋 Permission Summary Table (Minimal Set)

| Permission | Android | iOS | Purpose | Essential? |
|------------|---------|-----|---------|-----------|
| Internet | ✅ | ✅ (Default) | API calls, data sync | ✅ YES |
| Network State | ✅ | ✅ (Default) | Check connectivity | ✅ YES |
| Camera | ✅ | ✅ | Take photos | ✅ YES |
| Photo Library | ✅ | ✅ | Select images | ✅ YES |
| Storage/Media | ✅ | ✅ (Default) | Read images | ✅ YES |
| Notifications | ✅ | ✅ (Runtime) | Push notifications | ✅ YES |
| Vibration | ✅ | ✅ (Default) | Haptic feedback | ✅ YES |
| **REMOVED** | | | | |
| SMS | ❌ | ❌ | OTP autofill | ❌ NO |
| Phone State | ❌ | ❌ | Phone number | ❌ NO |
| Location | ❌ | ❌ | Service tracking | ❌ NO |
| Contacts | ❌ | ❌ | Contact selection | ❌ NO |
| Calendar | ❌ | ❌ | Appointments | ❌ NO |
| Bluetooth | ❌ | ❌ | Device connectivity | ❌ NO |
| Microphone | ❌ | ❌ | Audio recording | ❌ NO |
| Face ID | ❌ | ❌ | Biometric auth | ❌ NO |

---

## 🔒 Runtime Permissions

### Android (API 23+)
The following permissions require runtime requests:
- ✅ Camera (when taking photos)
- ✅ Storage/Media (when selecting images)
- ✅ Notifications (Android 13+ only)

**Note:** Internet and vibration permissions are granted automatically at install time.

### iOS
The following permissions require runtime requests:
- ✅ Camera (when taking photos)
- ✅ Photo Library (when selecting images)

**Note:** Notifications are requested at runtime when needed.

---

## 🧪 Testing Permissions

### Android
```bash
# Check granted permissions
adb shell dumpsys package com.example.customer_cracktreck | grep permission

# Grant camera permission
adb shell pm grant com.example.customer_cracktreck android.permission.CAMERA

# Grant storage permission (Android 12 and below)
adb shell pm grant com.example.customer_cracktreck android.permission.READ_EXTERNAL_STORAGE

# Grant notification permission (Android 13+)
adb shell pm grant com.example.customer_cracktreck android.permission.POST_NOTIFICATIONS

# Revoke permission
adb shell pm revoke com.example.customer_cracktreck android.permission.CAMERA

# Reset all permissions
adb shell pm reset-permissions
```

### iOS
1. Open Settings app
2. Scroll to "Customer Cracktreck"
3. View/modify permissions
4. Or reset: Settings > General > Reset > Reset Location & Privacy

---

## 📝 Important Notes

### Android 13+ (API 33) Changes
- ✅ Granular media permissions (images only, no videos)
- ✅ Notification permission required
- ✅ Photo picker doesn't need storage permission (recommended)

### iOS Privacy Guidelines
- ✅ Clear, specific usage descriptions required
- ✅ Users can revoke permissions anytime
- ✅ App must handle permission denial gracefully
- ✅ No unnecessary permissions requested

### App Store Compliance
- ✅ Only essential permissions requested
- ✅ Clear justification for each permission
- ✅ No sensitive permissions (SMS, Location, Contacts)
- ✅ Minimal permission footprint

---

## 🚀 Implementation Guide

### Using permission_handler Package (Recommended)

Add to `pubspec.yaml`:
```yaml
dependencies:
  permission_handler: ^11.0.0
```

Example usage:
```dart
import 'package:permission_handler/permission_handler.dart';

// Request camera permission
Future<void> requestCameraPermission() async {
  var status = await Permission.camera.request();

  if (status.isGranted) {
    // Permission granted - open camera
    openCamera();
  } else if (status.isDenied) {
    // Permission denied - show message
    showPermissionDeniedDialog();
  } else if (status.isPermanentlyDenied) {
    // Permission permanently denied - open settings
    openAppSettings();
  }
}

// Request storage permission
Future<void> requestStoragePermission() async {
  if (Platform.isAndroid) {
    if (await Permission.photos.request().isGranted) {
      // Android 13+
      openGallery();
    } else if (await Permission.storage.request().isGranted) {
      // Android 12 and below
      openGallery();
    }
  } else {
    // iOS
    if (await Permission.photos.request().isGranted) {
      openGallery();
    }
  }
}

// Request notification permission
Future<void> requestNotificationPermission() async {
  var status = await Permission.notification.request();
  if (status.isGranted) {
    // Enable notifications
  }
}
```

---

## ✅ App Store Review Checklist

### Google Play Store
- [x] Only essential permissions requested
- [x] No SMS permissions (sensitive)
- [x] No phone state permissions (sensitive)
- [x] No location permissions (sensitive)
- [x] Clear permission usage in app description
- [x] Runtime permission requests implemented
- [x] Graceful handling of denied permissions

### Apple App Store
- [x] Clear, specific usage descriptions
- [x] Only essential permissions requested
- [x] No unnecessary sensitive permissions
- [x] App Transport Security configured
- [x] Runtime permission requests implemented
- [x] Graceful handling of denied permissions

---

## 📄 Files Modified

1. ✅ `android/app/src/main/AndroidManifest.xml`
   - **Reduced from 19 to 7 permissions**
   - Removed all sensitive permissions
   - Added clear comments for each permission

2. ✅ `ios/Runner/Info.plist`
   - **Reduced from 16 to 2 permission descriptions**
   - Removed all unnecessary permissions
   - Clear, specific usage descriptions
   - App Transport Security configured

---

## 🎯 Summary

**Before:** 19 Android permissions + 16 iOS permissions = **35 total**
**After:** 7 Android permissions + 2 iOS permissions = **9 total**
**Reduction:** **74% fewer permissions** ✅

This minimal permission set ensures:
- ✅ App store compliance
- ✅ User trust and privacy
- ✅ Core functionality maintained
- ✅ Better app ratings
- ✅ Faster app review approval

