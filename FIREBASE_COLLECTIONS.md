# Firebase Firestore Collections Guide

This document provides the structure for all Firestore collections used in the School Management System.

## Required Collections

### 1. schools
Stores school information and configuration.

```json
{
  "schoolId": {
    "name": "Al Noor Public School",
    "logoUrl": "https://...",
    "primaryColor": "#673AB7",
    "secondaryColor": "#512DA8",
    "licenseStatus": "active",
    "expiryDate": "2025-12-31T00:00:00.000Z",
    "address": "School address",
    "contactNumber": "03001234567",
    "email": "info@school.edu.pk"
  }
}
```

### 2. users
Stores user authentication and role information.

```json
{
  "userId": {
    "email": "admin@school.edu.pk",
    "name": "Admin Name",
    "schoolId": "alnoor_001",
    "role": "principal",
    "createdAt": "2025-01-01T00:00:00.000Z"
  }
}
```

### 3. students
Stores student records with class assignments and status tracking.

```json
{
  "studentId": {
    "schoolId": "alnoor_001",
    "name": "Student Name",
    "fatherName": "Father Name",
    "classId": "class_doc_id",
    "className": "Class 5",
    "section": "A",
    "rollNumber": "001",
    "contact": "03001234567",
    "address": "Student address",
    "admissionDate": "2024-01-01T00:00:00.000Z",
    "photoUrl": "https://...",
    "status": "active",
    "graduationDate": null,
    "createdAt": "2025-01-01T00:00:00.000Z",
    "updatedAt": "2025-01-01T00:00:00.000Z",
    "synced": true
  }
}
```

**Status Values:**
- `active` - Currently enrolled student
- `graduated` - Student has graduated
- `left` - Student has left the school

**Required Index:**
- `schoolId` (Ascending) + `className` (Ascending)
- `schoolId` (Ascending) + `classId` (Ascending)
- `schoolId` (Ascending) + `status` (Ascending)

### 4. teachers
Stores teacher profiles and subject assignments.

```json
{
  "teacherId": {
    "schoolId": "alnoor_001",
    "name": "Teacher Name",
    "subjects": ["Mathematics", "Science"],
    "qualification": "MSc Mathematics",
    "contact": "03001234567",
    "email": "teacher@school.edu.pk",
    "joiningDate": "2024-01-01T00:00:00.000Z",
    "createdAt": "2025-01-01T00:00:00.000Z",
    "updatedAt": "2025-01-01T00:00:00.000Z",
    "synced": true
  }
}
```

**Required Index:**
- `schoolId` (Ascending)

### 5. classes
Stores class and section information with teacher assignments.

```json
{
  "classId": {
    "schoolId": "alnoor_001",
    "className": "Class 5",
    "section": "A",
    "classTeacherId": "teacher_doc_id",
    "capacity": 30,
    "subjects": [
      {
        "subjectName": "Mathematics",
        "teacherId": "teacher_doc_id",
        "teacherName": "Teacher Name"
      }
    ],
    "createdAt": "2025-01-01T00:00:00.000Z",
    "updatedAt": "2025-01-01T00:00:00.000Z",
    "synced": true
  }
}
```

**Required Index:**
- `schoolId` (Ascending)

### 6. subjects **(NEW)**
Stores subject definitions with optional teacher assignments.

```json
{
  "subjectId": {
    "schoolId": "alnoor_001",
    "name": "Mathematics",
    "shortCode": "MATH",
    "teacherId": "teacher_doc_id",
    "teacherName": "Teacher Name",
    "createdAt": "2025-01-01T00:00:00.000Z",
    "updatedAt": "2025-01-01T00:00:00.000Z",
    "synced": true
  }
}
```

**Required Index:**
- `schoolId` (Ascending)

### 7. timetable **(NEW)**
Stores weekly timetable entries for each class.

```json
{
  "timetableId": {
    "schoolId": "alnoor_001",
    "classId": "class_doc_id",
    "className": "Class 5 - A",
    "dayOfWeek": "Monday",
    "timeSlot": "08:00-08:45",
    "subjectId": "subject_doc_id",
    "subjectName": "Mathematics",
    "teacherId": "teacher_doc_id",
    "teacherName": "Teacher Name",
    "createdAt": "2025-01-01T00:00:00.000Z",
    "updatedAt": "2025-01-01T00:00:00.000Z",
    "synced": true
  }
}
```

**Required Index:**
- `schoolId` (Ascending) + `classId` (Ascending)
- `schoolId` (Ascending) + `classId` (Ascending) + `dayOfWeek` (Ascending)

### 8. attendance
Stores daily attendance records for students.

```json
{
  "attendanceId": {
    "schoolId": "alnoor_001",
    "studentId": "student_doc_id",
    "studentName": "Student Name",
    "classId": "class_doc_id",
    "className": "Class 5",
    "section": "A",
    "date": "2025-01-01T00:00:00.000Z",
    "status": "present",
    "remarks": "",
    "createdAt": "2025-01-01T00:00:00.000Z",
    "updatedAt": "2025-01-01T00:00:00.000Z",
    "synced": true
  }
}
```

**Required Index:**
- `schoolId` (Ascending) + `date` (Descending)
- `schoolId` (Ascending) + `classId` (Ascending) + `date` (Descending)

### 9. fees
Stores fee payment records for students.

```json
{
  "feeId": {
    "schoolId": "alnoor_001",
    "studentId": "student_doc_id",
    "studentName": "Student Name",
    "className": "Class 5",
    "section": "A",
    "month": "January 2025",
    "amount": 5000,
    "paidAmount": 5000,
    "status": "paid",
    "paymentDate": "2025-01-01T00:00:00.000Z",
    "createdAt": "2025-01-01T00:00:00.000Z",
    "updatedAt": "2025-01-01T00:00:00.000Z",
    "synced": true
  }
}
```

**Required Index:**
- `schoolId` (Ascending) + `studentId` (Ascending)
- `schoolId` (Ascending) + `month` (Ascending)

### 10. exams
Stores exam definitions and student results.

```json
{
  "examId": {
    "schoolId": "alnoor_001",
    "name": "Mid Term Exam",
    "className": "Class 5",
    "section": "A",
    "examDate": "2025-01-15T00:00:00.000Z",
    "subjects": [
      {
        "name": "Mathematics",
        "totalMarks": 100
      }
    ],
    "results": [
      {
        "studentId": "student_doc_id",
        "studentName": "Student Name",
        "marks": [
          {
            "subject": "Mathematics",
            "obtained": 85,
            "total": 100
          }
        ],
        "totalObtained": 85,
        "totalMarks": 100,
        "percentage": 85,
        "grade": "A"
      }
    ],
    "createdAt": "2025-01-01T00:00:00.000Z",
    "updatedAt": "2025-01-01T00:00:00.000Z",
    "synced": true
  }
}
```

**Required Index:**
- `schoolId` (Ascending) + `className` (Ascending)

## Security Rules

All collections must include security rules to ensure school-based data isolation:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function to check if user belongs to the school
    function isSchoolMember(schoolId) {
      return request.auth != null &&
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.schoolId == schoolId;
    }

    // Schools collection
    match /schools/{schoolId} {
      allow read: if request.auth != null;
      allow write: if false; // Only admins can modify
    }

    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if false; // Only auth system can modify
    }

    // Students collection
    match /students/{studentId} {
      allow read, write: if isSchoolMember(resource.data.schoolId);
    }

    // Teachers collection
    match /teachers/{teacherId} {
      allow read, write: if isSchoolMember(resource.data.schoolId);
    }

    // Classes collection
    match /classes/{classId} {
      allow read, write: if isSchoolMember(resource.data.schoolId);
    }

    // Subjects collection
    match /subjects/{subjectId} {
      allow read, write: if isSchoolMember(resource.data.schoolId);
    }

    // Timetable collection
    match /timetable/{timetableId} {
      allow read, write: if isSchoolMember(resource.data.schoolId);
    }

    // Attendance collection
    match /attendance/{attendanceId} {
      allow read, write: if isSchoolMember(resource.data.schoolId);
    }

    // Fees collection
    match /fees/{feeId} {
      allow read, write: if isSchoolMember(resource.data.schoolId);
    }

    // Exams collection
    match /exams/{examId} {
      allow read, write: if isSchoolMember(resource.data.schoolId);
    }
  }
}
```

## Setting Up Indexes

When you run the app, Firebase will automatically detect when indexes are needed and provide a link to create them. Click the link in the error message to auto-create the required index.

Common queries that need indexes:

1. **Students by school and class:**
   - Collection: `students`
   - Fields: `schoolId` (Ascending), `classId` (Ascending)

2. **Attendance by school, class, and date:**
   - Collection: `attendance`
   - Fields: `schoolId` (Ascending), `classId` (Ascending), `date` (Descending)

3. **Timetable by school and class:**
   - Collection: `timetable`
   - Fields: `schoolId` (Ascending), `classId` (Ascending)

## Initial Setup Checklist

- [ ] Create Firebase project
- [ ] Enable Email/Password authentication
- [ ] Create Firestore database
- [ ] Add security rules
- [ ] Create school document
- [ ] Create admin user in Authentication
- [ ] Create user document with matching schoolId
- [ ] Test login with admin credentials
- [ ] Add sample students, teachers, and classes
- [ ] Add sample subjects for timetable
- [ ] Create composite indexes as needed

## Data Migration Notes

If you're adding these new collections to an existing database:

1. **subjects**: Can start empty - create subjects as needed
2. **timetable**: Can start empty - create timetable entries as needed
3. **Existing students**: No changes needed - they already have classId
4. **Existing classes**: No changes needed - continue using as-is

The new modules are designed to work alongside existing data without requiring migrations.
