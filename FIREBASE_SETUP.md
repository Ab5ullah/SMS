# Firebase Setup Guide for School Management System

## Overview
This guide will help you set up Firebase for your School Management System desktop application.

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or "Create a project"
3. Enter your project name (e.g., "School-Management-System")
4. Click "Continue"
5. Disable Google Analytics (optional for desktop apps)
6. Click "Create project"
7. Wait for the project to be created, then click "Continue"

## Step 2: Register Your Windows App

1. In the Firebase console, click on the **Settings (gear icon)** > **Project settings**
2. Scroll down to "Your apps" section
3. Click on the **Web icon (</>)** to add a web app (we'll use web config for Windows)
4. Enter an app nickname (e.g., "School Management Desktop")
5. DO NOT check "Also set up Firebase Hosting"
6. Click "Register app"

## Step 3: Get Firebase Configuration

After registering the app, you'll see the Firebase SDK configuration. Copy these values:

```javascript
const firebaseConfig = {
  apiKey: "AIza...",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project-id",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abcdef"
};
```

## Step 4: Update main.dart

Open `lib/main.dart` and replace the Firebase configuration (lines 12-20) with your values:

```dart
await Firebase.initializeApp(
  options: const FirebaseOptions(
    apiKey: 'YOUR_API_KEY_HERE',
    appId: 'YOUR_APP_ID_HERE',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID_HERE',
    projectId: 'YOUR_PROJECT_ID_HERE',
    storageBucket: 'YOUR_STORAGE_BUCKET_HERE',
  ),
);
```

## Step 5: Enable Authentication

1. In Firebase Console, go to **Build** > **Authentication**
2. Click "Get started"
3. Click on "Email/Password" under Sign-in method
4. Enable "Email/Password"
5. Click "Save"

## Step 6: Create Firestore Database

1. In Firebase Console, go to **Build** > **Firestore Database**
2. Click "Create database"
3. Select "Start in production mode" (we'll add custom rules)
4. Choose a Cloud Firestore location (select closest to Pakistan: `asia-south1` - Mumbai)
5. Click "Enable"

## Step 7: Set Up Firestore Security Rules

1. Go to **Firestore Database** > **Rules** tab
2. Replace the default rules with the following:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper function to check if user is authenticated
    function isSignedIn() {
      return request.auth != null;
    }

    // Helper function to get user's school ID
    function getUserSchoolId() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.schoolId;
    }

    // Schools collection - read only for authenticated users
    match /schools/{schoolId} {
      allow read: if isSignedIn() && getUserSchoolId() == schoolId;
      allow write: if false; // Only admins can modify schools via backend
    }

    // Users collection
    match /users/{userId} {
      allow read: if isSignedIn() && request.auth.uid == userId;
      allow write: if false; // Only created via backend
    }

    // Students collection
    match /students/{studentId} {
      allow read, write: if isSignedIn() &&
        resource.data.schoolId == getUserSchoolId();
      allow create: if isSignedIn() &&
        request.resource.data.schoolId == getUserSchoolId();
    }

    // Teachers collection
    match /teachers/{teacherId} {
      allow read, write: if isSignedIn() &&
        resource.data.schoolId == getUserSchoolId();
      allow create: if isSignedIn() &&
        request.resource.data.schoolId == getUserSchoolId();
    }

    // Class sections collection
    match /class_sections/{classSectionId} {
      allow read, write: if isSignedIn() &&
        resource.data.schoolId == getUserSchoolId();
      allow create: if isSignedIn() &&
        request.resource.data.schoolId == getUserSchoolId();
    }

    // Attendance collection
    match /attendance/{attendanceId} {
      allow read, write: if isSignedIn() &&
        resource.data.schoolId == getUserSchoolId();
      allow create: if isSignedIn() &&
        request.resource.data.schoolId == getUserSchoolId();
    }

    // Fees collection
    match /fees/{feeId} {
      allow read, write: if isSignedIn() &&
        resource.data.schoolId == getUserSchoolId();
      allow create: if isSignedIn() &&
        request.resource.data.schoolId == getUserSchoolId();
    }

    // Exams collection
    match /exams/{examId} {
      allow read, write: if isSignedIn() &&
        resource.data.schoolId == getUserSchoolId();
      allow create: if isSignedIn() &&
        request.resource.data.schoolId == getUserSchoolId();
    }

    // Exam results collection
    match /exam_results/{resultId} {
      allow read, write: if isSignedIn() &&
        resource.data.schoolId == getUserSchoolId();
      allow create: if isSignedIn() &&
        request.resource.data.schoolId == getUserSchoolId();
    }
  }
}
```

3. Click "Publish"

## Step 8: Enable Firebase Storage

1. In Firebase Console, go to **Build** > **Storage**
2. Click "Get started"
3. Select "Start in production mode"
4. Click "Next"
5. Use the same location as Firestore
6. Click "Done"

## Step 9: Set Up Storage Security Rules

1. Go to **Storage** > **Rules** tab
2. Replace with:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /schools/{schoolId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
        firestore.get(/databases/(default)/documents/users/$(request.auth.uid)).data.schoolId == schoolId;
    }
  }
}
```

3. Click "Publish"

## Step 10: Create Sample Data for Testing

### Create a School Document

1. Go to **Firestore Database** > **Data** tab
2. Click "Start collection"
3. Collection ID: `schools`
4. Document ID: `alnoor_001` (or your school ID)
5. Add fields:
   - `name` (string): "Al Noor Public School"
   - `logoUrl` (string): "" (empty for now)
   - `primaryColor` (string): "#673AB7"
   - `secondaryColor` (string): "#512DA8"
   - `licenseStatus` (string): "active"
   - `expiryDate` (string): "2025-12-31T00:00:00.000Z"
   - `address` (string): "Your school address"
   - `contactNumber` (string): "03001234567"
   - `email` (string): "info@alnoor.edu.pk"
6. Click "Save"

### Create an Admin User in Firebase Authentication

1. Go to **Authentication** > **Users** tab
2. Click "Add user"
3. Email: `admin@alnoor.edu.pk`
4. Password: Create a strong password
5. Click "Add user"
6. Copy the **User UID** (you'll need this)

### Create User Document in Firestore

1. Go to **Firestore Database** > **Data** tab
2. Go to `users` collection (create if doesn't exist)
3. Document ID: [Paste the User UID you copied]
4. Add fields:
   - `email` (string): "admin@alnoor.edu.pk"
   - `name` (string): "Admin User"
   - `schoolId` (string): "alnoor_001"
   - `role` (string): "principal"
   - `createdAt` (string): "2025-01-01T00:00:00.000Z"
5. Click "Save"

## Step 11: Install Dependencies

Run the following command in your project directory:

```bash
flutter pub get
```

## Step 12: Run the Application

```bash
flutter run -d windows
```

## Login Credentials for Testing

- **Email**: admin@alnoor.edu.pk
- **Password**: [The password you set in Authentication]

## Important Notes

1. **Security**: The Firebase configuration in `main.dart` is safe to commit to version control as it's meant to be public. The security comes from Firestore security rules.

2. **License Management**: To expire a license, change the `licenseStatus` to "inactive" or set `expiryDate` to a past date in the school document.

3. **Multiple Schools**: Create additional school documents with different `schoolId` values, then create users with corresponding `schoolId` values.

4. **Production**: Before deploying, ensure:
   - All security rules are properly configured
   - Strong passwords are used for all accounts
   - Regular backups are enabled in Firebase Console

## Troubleshooting

### Connection Issues
- Check internet connection
- Verify Firebase credentials are correct in `main.dart`
- Check Firebase Console for any service issues

### Authentication Fails
- Ensure Email/Password authentication is enabled
- Verify user exists in Authentication tab
- Check that user document exists in Firestore with correct `schoolId`

### License Expired Error
- Check the `licenseStatus` field is "active"
- Verify `expiryDate` is in the future
- Format: "YYYY-MM-DDTHH:mm:ss.000Z"

## Next Steps

After completing Firebase setup, you can:
1. Add more schools and users
2. Test the authentication flow
3. Implement the remaining modules (Students, Teachers, etc.)
4. Set up offline sync
5. Configure Windows .exe build for distribution
