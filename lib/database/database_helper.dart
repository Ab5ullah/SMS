import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('school_management.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Initialize FFI for desktop
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    final String dbPath = join(appDocumentsDir.path, 'SchoolManagementSystem', filePath);

    // Create directory if it doesn't exist
    final Directory dbDir = Directory(dirname(dbPath));
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';
    const boolType = 'INTEGER NOT NULL';

    // School table
    await db.execute('''
      CREATE TABLE schools (
        id $idType,
        name $textType,
        logoUrl TEXT,
        primaryColor $textType,
        secondaryColor $textType,
        licenseStatus $textType,
        expiryDate $textType,
        address TEXT,
        contactNumber TEXT,
        email TEXT
      )
    ''');

    // Users table
    await db.execute('''
      CREATE TABLE users (
        id $idType,
        email $textType,
        name $textType,
        schoolId $textType,
        role $textType,
        createdAt $textType
      )
    ''');

    // Students table
    await db.execute('''
      CREATE TABLE students (
        id $idType,
        schoolId $textType,
        name $textType,
        fatherName $textType,
        className $textType,
        section $textType,
        rollNumber $textType,
        contact $textType,
        address TEXT,
        admissionDate $textType,
        photoUrl TEXT,
        createdAt $textType,
        updatedAt $textType,
        synced $boolType
      )
    ''');

    // Teachers table
    await db.execute('''
      CREATE TABLE teachers (
        id $idType,
        schoolId $textType,
        name $textType,
        contact $textType,
        email $textType,
        address TEXT,
        subjects TEXT,
        assignedClasses TEXT,
        qualification $textType,
        joiningDate $textType,
        photoUrl TEXT,
        createdAt $textType,
        updatedAt $textType,
        synced $boolType
      )
    ''');

    // Classes table
    await db.execute('''
      CREATE TABLE class_sections (
        id $idType,
        schoolId $textType,
        className $textType,
        section $textType,
        classTeacherId TEXT,
        capacity $intType,
        createdAt $textType,
        updatedAt $textType,
        synced $boolType
      )
    ''');

    // Attendance table
    await db.execute('''
      CREATE TABLE attendance (
        id $idType,
        schoolId $textType,
        studentId $textType,
        className $textType,
        section $textType,
        date $textType,
        status $textType,
        remarks TEXT,
        createdAt $textType,
        updatedAt $textType,
        synced $boolType
      )
    ''');

    // Fees table
    await db.execute('''
      CREATE TABLE fees (
        id $idType,
        schoolId $textType,
        studentId $textType,
        studentName $textType,
        className $textType,
        section $textType,
        amount $realType,
        paidAmount $realType,
        dueDate $textType,
        paidDate TEXT,
        status $textType,
        month $textType,
        year $intType,
        remarks TEXT,
        createdAt $textType,
        updatedAt $textType,
        synced $boolType
      )
    ''');

    // Exams table
    await db.execute('''
      CREATE TABLE exams (
        id $idType,
        schoolId $textType,
        name $textType,
        className $textType,
        section $textType,
        subject $textType,
        examDate $textType,
        totalMarks $intType,
        passingMarks $intType,
        remarks TEXT,
        createdAt $textType,
        updatedAt $textType,
        synced $boolType
      )
    ''');

    // Exam Results table
    await db.execute('''
      CREATE TABLE exam_results (
        id $idType,
        schoolId $textType,
        examId $textType,
        studentId $textType,
        studentName $textType,
        marksObtained $realType,
        grade $textType,
        remarks TEXT,
        createdAt $textType,
        updatedAt $textType,
        synced $boolType
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_students_school ON students(schoolId)');
    await db.execute('CREATE INDEX idx_students_class ON students(className, section)');
    await db.execute('CREATE INDEX idx_teachers_school ON teachers(schoolId)');
    await db.execute('CREATE INDEX idx_attendance_date ON attendance(date, schoolId)');
    await db.execute('CREATE INDEX idx_fees_status ON fees(status, schoolId)');
    await db.execute('CREATE INDEX idx_exams_school ON exams(schoolId)');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  Future<void> clearDatabase() async {
    final db = await instance.database;
    await db.delete('schools');
    await db.delete('users');
    await db.delete('students');
    await db.delete('teachers');
    await db.delete('class_sections');
    await db.delete('attendance');
    await db.delete('fees');
    await db.delete('exams');
    await db.delete('exam_results');
  }
}
