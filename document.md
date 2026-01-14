# Aadhar Card API Integration Documentation

This document outlines the steps taken to integrate the Aadhar Card GET API into the `DocumentsScreen`.

## 1. API Endpoint Configuration
The API endpoint was already defined in `lib/constants/api_constants.dart`:
```dart
static const String aadharCard = '$baseUrl/aadhar-card';
```

## 2. Integration Steps in `documents_screen.dart`

### A. Dependency Imports
Imported necessary services for network requests and data persistence:
- `api_client.dart`: To perform the HTTP GET request.
- `secure_storage_service.dart`: To retrieve the stored `userId`, `roleId`, and `accessToken`.
- `api_constants.dart`: To access the Aadhar Card endpoint.

### B. State Management
Added new state variables to handle the API response and loading status:
- `_isLoading`: A boolean to show a loader while fetching data.
- `_aadharFrontUrl` & `_aadharBackUrl`: To store the image paths returned by the API.
- Initialized `_aadharNumber` as an empty string to be populated by the API.

### C. Fetching Data (`_fetchAadharDetails`)
Implemented a method to fetch data upon screen initialization:
1. **Retrieve Credentials**: Fetched `userId`, `roleId`, and `token` asynchronously from `SecureStorageService`.
2. **Construct URL**: Appended query parameters to the base Aadhar constant as per Postman specifications: `?user_id=$userId&role_id=$roleId`.
3. **Execute GET Request**: Used `ApiClient.get(url, token: token)` to fetch data.
4. **Update State**: Parsed the `aadhar_card` object from the JSON response and updated the UI state with the Aadhar number and formatted image URLs (prefixed with `https://crackteck.co.in/`).

### D. UI Enhancements
- **Loading State**: Wrapped the screen body in a conditional check to show a `CircularProgressIndicator` while `_isLoading` is true.
- **Refresh Indicator**: Added a `RefreshIndicator` to allow users to manually refresh their document status.
- **Dynamic Image Loading**:
    - Updated `_buildImagePreview` to accept both local `File` objects (for newly selected images) and remote `URL` strings (for existing documents).
    - Used `Image.network` with a `loadingBuilder` and `errorBuilder` to ensure a smooth user experience.

## 3. Changes Summary
- **Logic**: Moved from static placeholder data to dynamic data fetching from the backend.
- **Services**: Utilized `SecureStorageService` to make the API call user-specific.
- **UX**: Added loading spinners and error handling for network requests.
