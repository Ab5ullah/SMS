# School Management System - Complete Project Documentation

## Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture & Design](#architecture--design)
3. [Features Implementation](#features-implementation)
4. [Data Models](#data-models)
5. [UI/UX Design System](#uiux-design-system)
6. [Recent Updates & Fixes](#recent-updates--fixes)
7. [Technical Details](#technical-details)
8. [Future Enhancements](#future-enhancements)

---

## Project Overview

### Vision
Create a comprehensive, user-friendly School Management System tailored for lower and middle-level schools in Pakistan, enabling efficient management of all school operations through a modern desktop application.

### Target Users
- School Principals
- School Administrators
- Academic Coordinators
- Administrative Staff

### Key Objectives
- Simplify student enrollment and record management
- Streamline attendance tracking
- Automate fee collection and payment tracking
- Facilitate exam management and result generation
- Provide real-time insights through analytics dashboard
- Ensure data security with multi-tenant architecture

---

## Architecture & Design

### Technology Stack

#### Frontend
- **Framework**: Flutter (Cross-platform - Web/Desktop)
- **Language**: Dart
- **UI Approach**: Material Design with custom theme
- **State Management**: Provider pattern

#### Backend
- **Database**: Firebase Firestore (NoSQL)
- **Authentication**: Firebase Authentication
- **Storage**: Firebase Storage (for photos and documents)
- **Hosting**: Firebase Hosting (Web deployment)

#### Design System
- **Colors**: AppColors (Light/Dark theme support)
- **Typography**: AppTypography (Consistent text styles)
- **Spacing**: AppSpacing (8px grid system)
- **Components**: Custom reusable widgets

### Project Structure

```
lib/
├── database/                  # Local SQLite helpers
│   └── database_helper.dart
├── models/                    # Data models
│   ├── school.dart
│   ├── user.dart
│   ├── student.dart
│   ├── teacher.dart
│   ├── class_section.dart   # NEW: Subject assignments
│   ├── attendance.dart
│   ├── fee.dart
│   └── exam.dart
├── providers/                 # State management
│   └── auth_provider.dart
├── screens/                   # UI screens
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── dashboard_screen.dart
│   ├── students/
│   │   ├── students_screen.dart
│   │   └── add_edit_student_screen.dart  # ENHANCED: Capacity validation
│   ├── teachers/
│   │   ├── teachers_screen.dart
│   │   └── add_edit_teacher_screen.dart
│   ├── classes/
│   │   ├── classes_screen.dart  # ENHANCED: Teacher names, student lists
│   │   └── add_edit_class_screen.dart  # NEW: Subject-teacher assignment
│   ├── attendance/
│   │   └── attendance_screen.dart
│   ├── fees/
│   │   └── fees_screen.dart
│   └── exams/
│       └── exams_screen.dart
├── services/                  # Business logic
│   ├── auth_service.dart
│   └── firestore_service.dart
├── theme/                     # Design system
│   ├── app_colors.dart
│   ├── app_spacing.dart
│   └── app_typography.dart
├── utils/                     # Utilities
│   ├── constants.dart
│   ├── helpers.dart
│   └── logger.dart
├── widgets/                   # Custom widgets
│   └── custom_widgets.dart  # ENHANCED: Dialog overflow fix
└── main.dart                  # App entry point
```

### Multi-Tenant Architecture

The system uses a school-based multi-tenant architecture:

```
Firebase Firestore Structure:
├── schools/
│   └── {schoolId}/
│       ├── name
│       ├── logoUrl
│       ├── primaryColor
│       ├── licenseStatus
│       └── expiryDate
├── users/
│   └── {userId}/
│       ├── email
│       ├── name
│       ├── schoolId  ← Links user to school
│       └── role
├── students/
│   └── {studentId}/
│       ├── schoolId  ← Isolates data by school
│       ├── classId   ← NEW: References class document
│       ├── name
│       └── ...
├── teachers/
│   └── {teacherId}/
│       ├── schoolId  ← Isolates data by school
│       └── ...
├── classes/
│   └── {classId}/
│       ├── schoolId  ← Isolates data by school
│       ├── classTeacherId
│       ├── capacity
│       ├── subjects  ← NEW: Array of subject assignments
│       └── ...
└── [other collections with schoolId]
```

**Security Rules**: All Firestore queries filter by `schoolId` to ensure data isolation between schools.

---

## Features Implementation

### 1. Authentication & License Management

**Implementation**: `lib/screens/splash_screen.dart`, `lib/screens/login_screen.dart`

**Features**:
- Firebase email/password authentication
- License validation on startup
- Automatic expiry checking
- Session management with Provider

**Flow**:
1. App starts → Splash screen checks license
2. If expired → Show license expired page
3. If active → Show login screen
4. After login → Verify schoolId and navigate to dashboard

### 2. Dashboard

**Implementation**: `lib/screens/dashboard_screen.dart`

**Features**:
- Real-time statistics cards:
  - Total students
  - Total teachers
  - Total classes
  - Today's attendance
  - Total fees collected
  - Pending fees
- Quick action buttons
- Recent activity feed
- School branding (logo and colors)

**Data Sources**:
- StreamBuilder widgets for real-time updates
- Firestore aggregation queries filtered by schoolId

### 3. Student Management

**Implementation**: `lib/screens/students/`

**Features**:
- **List View**: Paginated table with student details
- **Grid View**: Card-based layout with photos
- **Search**: Real-time search by name, roll number
- **Filter**: By class and section
- **Add/Edit**: Form with validation
- **Delete**: Confirmation dialog with cascade checks
- **Class Assignment**: Dropdown selector with capacity validation
- **Photo Upload**: Firebase Storage integration

**Recent Enhancements**:
- ✅ Added `classId` field to Student model for proper class reference
- ✅ Class selector now shows capacity information
- ✅ Real-time capacity validation prevents over-enrollment
- ✅ Visual indicator shows available spots (color-coded)

**Data Model** (`lib/models/student.dart`):
```dart
class Student {
  final String? id;
  final String schoolId;
  final String name;
  final String fatherName;
  final String? classId;  // NEW: References class document
  final String className; // Denormalized for quick access
  final String section;
  final String rollNumber;
  final String contact;
  final String address;
  final DateTime admissionDate;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;
}
```

### 4. Teacher Management

**Implementation**: `lib/screens/teachers/`

**Features**:
- List and grid view options
- Search and filter capabilities
- Subject assignment (multiple subjects per teacher)
- Qualification tracking
- Contact information management
- Photo upload support

**Data Model** (`lib/models/teacher.dart`):
```dart
class Teacher {
  final String? id;
  final String schoolId;
  final String name;
  final String qualification;
  final List<String> subjects;
  final String contact;
  final String address;
  final DateTime joiningDate;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;
}
```

### 5. Class & Section Management ⭐ ENHANCED

**Implementation**: `lib/screens/classes/`

**Features**:
- **Create Classes**: Define class name, section, capacity
- **Class Teacher Assignment**: Assign one teacher as class head
- **Subject-Teacher Assignment**: Assign specific teachers to subjects
- **Capacity Management**: Set maximum student capacity
- **Student List View**: See all enrolled students in real-time
- **Teacher Name Display**: Shows actual teacher names (not IDs)

**Recent Enhancements**:
- ✅ Added subject-wise teacher assignment system
- ✅ Display teacher names instead of IDs using StreamBuilder
- ✅ Show assigned students in class details dialog
- ✅ Fixed dialog overflow issues with scrollable content
- ✅ Capacity validation prevents over-enrollment

**Data Model** (`lib/models/class_section.dart`):
```dart
class SubjectAssignment {
  final String subjectName;
  final String? teacherId;
  final String? teacherName;
}

class ClassSection {
  final String? id;
  final String schoolId;
  final String className;
  final String section;
  final String? classTeacherId;
  final int capacity;
  final List<SubjectAssignment> subjects;  // NEW: Subject assignments
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;
}
```

**UI Components**:

1. **Classes List Screen** (`classes_screen.dart`):
   - Grid view of all classes
   - Each card shows class name, section, capacity
   - Click to view detailed information
   - Quick edit and delete actions

2. **Class Details Dialog**:
   - Class information (name, section, capacity)
   - Class teacher name (fetched from Firestore)
   - Subject-teacher assignments list
   - Assigned students list (real-time)
   - Edit and delete actions

3. **Add/Edit Class Screen** (`add_edit_class_screen.dart`):
   - Basic Information section:
     - Class name input
     - Section input
     - Capacity input
   - Class Teacher Head section:
     - Dropdown to select class teacher
     - Shows teacher name and subjects
   - Subject-wise Teacher Assignment section:
     - Add multiple subjects
     - Assign teacher to each subject
     - Delete subject assignments
     - Duplicate subject validation

### 6. Attendance Management

**Implementation**: `lib/screens/attendance/`

**Features**:
- Date picker for attendance date
- Class and section selector
- Student list with status toggle (Present/Absent/Leave)
- Bulk actions (Mark all present/absent)
- Save and update attendance
- View historical attendance

**Data Model** (`lib/models/attendance.dart`):
```dart
class Attendance {
  final String? id;
  final String schoolId;
  final String studentId;
  final String className;
  final String section;
  final DateTime date;
  final String status; // Present, Absent, Leave
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;
}
```

### 7. Fee Management

**Implementation**: `lib/screens/fees/`

**Features**:
- Student-wise fee records
- Monthly fee tracking
- Payment status (Paid, Unpaid, Partial)
- Payment amount and date
- Remarks/notes
- Fee history view
- Outstanding balance calculation

**Data Model** (`lib/models/fee.dart`):
```dart
class Fee {
  final String? id;
  final String schoolId;
  final String studentId;
  final String month;
  final int year;
  final double amount;
  final double paidAmount;
  final String status; // Paid, Unpaid, Partial
  final DateTime? paidDate;
  final String? remarks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;
}
```

### 8. Exam & Results Management

**Implementation**: `lib/screens/exams/`

**Features**:
- Create exams with name and date
- Define subjects for each exam
- Set maximum marks per subject
- Enter student marks
- Automatic grade calculation
- Result sheet generation
- Performance analytics

**Data Model** (`lib/models/exam.dart`):
```dart
class ExamSubject {
  final String subjectName;
  final int maxMarks;
}

class Exam {
  final String? id;
  final String schoolId;
  final String name;
  final String className;
  final String section;
  final DateTime examDate;
  final List<ExamSubject> subjects;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;
}

class ExamResult {
  final String? id;
  final String schoolId;
  final String examId;
  final String studentId;
  final Map<String, int> marks; // {subjectName: marks}
  final int totalMarks;
  final int obtainedMarks;
  final double percentage;
  final String grade;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;
}
```

---

## Data Models

### School Model
```dart
class School {
  final String? id;
  final String name;
  final String? logoUrl;
  final String? primaryColor;
  final String? secondaryColor;
  final String licenseStatus; // active, inactive
  final DateTime? expiryDate;
  final String address;
  final String contactNumber;
  final String email;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### User Model
```dart
class User {
  final String? id;
  final String email;
  final String name;
  final String schoolId;
  final String role; // principal, admin, teacher
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

---

## UI/UX Design System

### Theme Architecture

#### 1. AppColors (`lib/theme/app_colors.dart`)

**Color Palette**:

**Light Theme**:
- Primary: Blue 600 (#2563EB)
- Secondary: Violet 600 (#7C3AED)
- Background: Gray 50 (#F9FAFB)
- Surface: White (#FFFFFF)
- Text Primary: Gray 900 (#111827)
- Text Secondary: Gray 500 (#6B7280)

**Dark Theme**:
- Primary: Blue 500 (#3B82F6)
- Secondary: Violet 500 (#8B5CF6)
- Background: Slate 900 (#0F172A)
- Surface: Slate 800 (#1E293B)
- Text Primary: Gray 50 (#F9FAFB)
- Text Secondary: Slate 400 (#94A3B8)

**Module-Specific Colors**:
- Students: Blue 500 (#3B82F6)
- Teachers: Violet 500 (#8B5CF6)
- Classes: Green 500 (#10B981)
- Attendance: Cyan 500 (#06B6D4)
- Fees: Blue 500 (#3B82F6)
- Exams: Indigo 500 (#6366F1)

**Status Colors**:
- Success: Green 500/400
- Warning: Amber 500/400
- Error: Red 500/400
- Info: Blue 500/400

#### 2. AppTypography (`lib/theme/app_typography.dart`)

**Text Styles**:
- Display Large: 57px, Regular
- Display Medium: 45px, Regular
- Display Small: 36px, Regular
- Headline Large: 32px, Regular
- Headline Medium: 28px, Regular
- Headline Small: 24px, Regular
- Title Large: 22px, Medium
- Title Medium: 16px, Medium
- Title Small: 14px, Medium
- Body Large: 16px, Regular
- Body Medium: 14px, Regular
- Body Small: 12px, Regular
- Label Large: 14px, Medium
- Label Medium: 12px, Medium
- Label Small: 11px, Medium

#### 3. AppSpacing (`lib/theme/app_spacing.dart`)

**Spacing System** (8px grid):
- xs: 4px
- sm: 8px
- md: 16px
- lg: 24px
- xl: 32px
- xxl: 48px

**Border Radius**:
- xs: 4px
- sm: 8px
- md: 12px
- lg: 16px
- xl: 24px

**Icon Sizes**:
- sm: 16px
- md: 24px
- lg: 32px
- xl: 48px

### Custom Widgets (`lib/widgets/custom_widgets.dart`)

#### 1. CustomButton
**Variants**:
- Primary: Filled with primary color
- Secondary: Filled with secondary color
- Success: Filled with success color
- Danger: Filled with error color
- Outline: Border with transparent background
- Ghost: Transparent with hover effect

**Sizes**:
- Small: 8px vertical padding
- Medium: 25px vertical padding
- Large: 16px vertical padding

**Features**:
- Icon support
- Loading state
- Hover animations
- Full-width option

#### 2. CustomCard
**Features**:
- Elevated with shadow
- Rounded corners
- Hover effect (lift animation)
- Tap support
- Customizable padding

#### 3. CustomTextField
**Features**:
- Label and hint text
- Prefix and suffix icons
- Validation support
- Focus animations
- Multi-line support
- Disabled state

#### 4. CustomDialog ⭐ ENHANCED
**Features**:
- Title with optional icon
- Scrollable content (NEW: Fixed overflow)
- Action buttons
- Confirmation variant
- Flexible layout

**Recent Fix**:
- Added `maxHeight: 600` constraint
- Wrapped content in `Flexible` widget
- Prevents bottom overflow on large content

#### 5. ModernSearchBar
**Features**:
- Search icon
- Clear button
- Focus animations
- Border highlight
- Debounced input

#### 6. StatsCard
**Features**:
- Icon with colored background
- Value display (large text)
- Title and subtitle
- Tap support
- Module-specific colors

#### 7. ModernEmptyState
**Features**:
- Large icon
- Title and subtitle
- Optional action button
- Centered layout

---

## Recent Updates & Fixes

### Phase 1: Class-Student Assignment System
**Date**: Previous session

**Changes**:
1. Added `classId` field to Student model
2. Created class dropdown selector in student form
3. Implemented student-class relationship
4. Fixed Firestore security rules for student queries

**Files Modified**:
- `lib/models/student.dart`
- `lib/screens/students/add_edit_student_screen.dart`

### Phase 2: Teacher Assignment System
**Date**: Previous session

**Changes**:
1. Added subject-teacher assignment in class creation
2. Implemented `SubjectAssignment` model
3. Created dynamic subject row UI
4. Added duplicate subject validation

**Files Modified**:
- `lib/models/class_section.dart`
- `lib/screens/classes/add_edit_class_screen.dart`

### Phase 3: Enhanced Class Details Display
**Date**: Previous session

**Changes**:
1. Display teacher names instead of IDs using StreamBuilder
2. Show assigned students in class details
3. Added subject-teacher chips in class dialog
4. Implemented real-time student count

**Files Modified**:
- `lib/screens/classes/classes_screen.dart`

### Phase 4: Capacity Validation & UI Fixes ⭐ LATEST
**Date**: Current session

**Changes**:

1. **Fixed Dialog Overflow Issue**:
   - Added `maxHeight: 600` constraint to CustomDialog
   - Wrapped content in `Flexible` widget
   - Prevents overflow when viewing class details
   - **File**: `lib/widgets/custom_widgets.dart:593-627`

2. **Implemented Capacity Validation**:
   - Checks class capacity before student enrollment
   - Fetches current student count from Firestore
   - Excludes current student when editing
   - Shows error message when class is full
   - **File**: `lib/screens/students/add_edit_student_screen.dart:86-123`

3. **Enhanced Student Enrollment UI**:
   - Added capacity display in class dropdown
   - Real-time availability indicator
   - Color-coded status (Green < 80%, Amber 80-99%, Red 100%)
   - Shows "X / Y students (Z spots available)"
   - **File**: `lib/screens/students/add_edit_student_screen.dart:646-721`

**Impact**:
- ✅ Prevents overbooking of classes
- ✅ Provides visual feedback on capacity
- ✅ Improves user experience with real-time data
- ✅ Fixes UI overflow issues in dialogs

---

## Technical Details

### State Management

**Provider Pattern**:
```dart
// lib/providers/auth_provider.dart
class AuthProvider with ChangeNotifier {
  User? _currentUser;
  School? _currentSchool;

  User? get currentUser => _currentUser;
  School? get currentSchool => _currentSchool;

  Future<void> login(String email, String password) async {
    // Authentication logic
    notifyListeners();
  }

  Future<void> logout() async {
    // Logout logic
    notifyListeners();
  }
}
```

**Usage in Widgets**:
```dart
// Access provider
final authProvider = Provider.of<AuthProvider>(context);

// Use data
Text('Welcome, ${authProvider.currentUser?.name}');

// Listen to changes
Consumer<AuthProvider>(
  builder: (context, auth, child) {
    return Text(auth.currentSchool?.name ?? '');
  },
);
```

### Firebase Integration

**Firestore Queries**:
```dart
// Fetch students for a school
FirebaseFirestore.instance
  .collection('students')
  .where('schoolId', isEqualTo: schoolId)
  .orderBy('name')
  .snapshots()
  .listen((snapshot) {
    final students = snapshot.docs
      .map((doc) => Student.fromMap(doc.data(), doc.id))
      .toList();
  });
```

**Real-time Updates**:
```dart
// StreamBuilder for live data
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
    .collection('classes')
    .where('schoolId', isEqualTo: schoolId)
    .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final classes = snapshot.data!.docs
        .map((doc) => ClassSection.fromMap(doc.data(), doc.id))
        .toList();
      return ClassListView(classes: classes);
    }
    return LoadingWidget();
  },
);
```

### Security Rules

**Firestore Rules**:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function getUserSchoolId() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.schoolId;
    }

    function belongsToSchool(schoolId) {
      return isAuthenticated() && getUserSchoolId() == schoolId;
    }

    // Schools collection
    match /schools/{schoolId} {
      allow read: if isAuthenticated();
      allow write: if false; // Only admins can modify
    }

    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated() && request.auth.uid == userId;
      allow write: if false; // Only system can modify
    }

    // Students collection
    match /students/{studentId} {
      allow read, write: if belongsToSchool(resource.data.schoolId);
      allow create: if belongsToSchool(request.resource.data.schoolId);
    }

    // Teachers collection
    match /teachers/{teacherId} {
      allow read, write: if belongsToSchool(resource.data.schoolId);
      allow create: if belongsToSchool(request.resource.data.schoolId);
    }

    // Classes collection
    match /classes/{classId} {
      allow read, write: if belongsToSchool(resource.data.schoolId);
      allow create: if belongsToSchool(request.resource.data.schoolId);
    }

    // Attendance collection
    match /attendance/{attendanceId} {
      allow read, write: if belongsToSchool(resource.data.schoolId);
      allow create: if belongsToSchool(request.resource.data.schoolId);
    }

    // Fees collection
    match /fees/{feeId} {
      allow read, write: if belongsToSchool(resource.data.schoolId);
      allow create: if belongsToSchool(request.resource.data.schoolId);
    }

    // Exams collection
    match /exams/{examId} {
      allow read, write: if belongsToSchool(resource.data.schoolId);
      allow create: if belongsToSchool(request.resource.data.schoolId);
    }
  }
}
```

### Performance Optimization

**Strategies**:
1. **Pagination**: Limit query results with `.limit()`
2. **Indexing**: Create composite indexes for common queries
3. **Caching**: Use StreamBuilder for automatic caching
4. **Lazy Loading**: Load data on demand
5. **Debouncing**: Delay search queries to reduce reads
6. **Denormalization**: Store frequently accessed data together

**Example - Paginated Query**:
```dart
Query query = FirebaseFirestore.instance
  .collection('students')
  .where('schoolId', isEqualTo: schoolId)
  .orderBy('name')
  .limit(20);

// Load more
if (lastDocument != null) {
  query = query.startAfterDocument(lastDocument);
}
```

---

## Future Enhancements

### Priority 1: High Priority

1. **Reports & Export System**
   - PDF generation for reports
   - Excel export functionality
   - Customizable report templates
   - Print-friendly layouts
   - School branding on reports

2. **Offline Mode**
   - SQLite local database
   - Sync mechanism
   - Conflict resolution
   - Queue for pending operations

3. **Windows Desktop Build**
   - Resolve Firebase C++ SDK issues
   - Create installer package
   - Auto-update mechanism
   - Desktop notifications

### Priority 2: Medium Priority

4. **Advanced Analytics**
   - Student performance trends
   - Attendance analytics
   - Fee collection reports
   - Class-wise comparisons
   - Interactive charts (fl_chart package)

5. **Communication System**
   - Email notifications
   - SMS integration
   - Parent portal access
   - Announcement system
   - Emergency alerts

6. **Enhanced Security**
   - Local data encryption
   - Role-based permissions
   - Audit logging
   - Session timeout
   - Two-factor authentication

### Priority 3: Future Features

7. **Parent Portal**
   - View student details
   - Check attendance
   - View fee status
   - Access exam results
   - Receive notifications

8. **Mobile App**
   - iOS app
   - Android app
   - Push notifications
   - Offline access
   - QR code scanning

9. **Advanced Features**
   - Timetable management
   - Library management
   - Transport management
   - Inventory management
   - HR & Payroll

10. **AI/ML Integration**
    - Predictive analytics
    - Student performance prediction
    - Attendance pattern analysis
    - Fee defaulter prediction
    - Automated insights

---

## Development Guidelines

### Code Style

**Naming Conventions**:
- Classes: PascalCase (e.g., `StudentScreen`)
- Variables: camelCase (e.g., `studentName`)
- Constants: SCREAMING_SNAKE_CASE (e.g., `MAX_CAPACITY`)
- Private members: _camelCase (e.g., `_isLoading`)

**File Organization**:
- One class per file
- Group related files in folders
- Use barrel exports for convenience

**Comments**:
```dart
// Single-line comment for simple explanations

/// Documentation comment for public APIs
/// Includes parameter descriptions and examples

// TODO: Future improvement
// FIXME: Known issue to address
```

### Testing Strategy

**Unit Tests**:
- Test data models
- Test utility functions
- Test business logic

**Widget Tests**:
- Test UI components
- Test user interactions
- Test navigation

**Integration Tests**:
- Test complete user flows
- Test Firebase integration
- Test authentication

### Git Workflow

**Branch Strategy**:
- `main`: Production-ready code
- `develop`: Development branch
- `feature/*`: New features
- `bugfix/*`: Bug fixes
- `hotfix/*`: Critical fixes

**Commit Messages**:
```
feat: Add subject-teacher assignment
fix: Resolve dialog overflow issue
docs: Update README with new features
refactor: Improve code structure
test: Add unit tests for Student model
```

---

## Troubleshooting

### Common Issues

**Issue 1: Firebase Connection Fails**
- **Solution**: Check internet connection, verify Firebase config

**Issue 2: Permission Denied Errors**
- **Solution**: Update Firestore security rules, verify schoolId

**Issue 3: Data Not Syncing**
- **Solution**: Check network, verify Firestore indexes

**Issue 4: Dialog Overflow**
- **Solution**: ✅ Fixed in v1.1.0 with flexible layout

**Issue 5: Capacity Validation Not Working**
- **Solution**: ✅ Fixed in v1.1.0 with real-time checks

**Issue 6: Windows Build Fails**
- **Solution**: Use web version, desktop support in progress

---

## Version History

### v1.1.0 (January 2025) - Current
**Major Updates**:
- ✅ Class capacity validation system
- ✅ Real-time capacity indicators
- ✅ Subject-teacher assignment
- ✅ Fixed dialog overflow issues
- ✅ Display teacher names in class details
- ✅ Show assigned students in classes

**Bug Fixes**:
- Fixed CustomDialog overflow on large content
- Fixed capacity enforcement in student enrollment
- Fixed teacher name display using StreamBuilder

### v1.0.0 (January 2025) - Initial Release
**Features**:
- Complete UI/UX redesign
- All core modules implemented
- Firebase integration
- Multi-tenant architecture
- Dark mode support
- Search and filtering

---

## Credits & Acknowledgments

**Development Team**:
- Lead Developer: [Your Name]
- UI/UX Designer: [Your Name]
- Project Manager: [Your Name]

**Technologies Used**:
- Flutter & Dart
- Firebase (Firestore, Auth, Storage, Hosting)
- Material Design
- Provider State Management

**Special Thanks**:
- Flutter community for excellent documentation
- Firebase team for robust backend services
- Material Design for design guidelines

---

## Contact & Support

For technical support or inquiries:
- Email: [your-email@example.com]
- GitHub: [your-github-repo]
- Documentation: See README.md and FIREBASE_SETUP.md

---

**Document Version**: 1.1.0
**Last Updated**: January 2025
**Maintained By**: Development Team

---

*This documentation is continuously updated as the project evolves. Please refer to the latest version for accurate information.*
