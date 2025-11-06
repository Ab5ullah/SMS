import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window manager only for desktop (not web)
  if (!kIsWeb) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720),
      minimumSize: Size(1024, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      title: 'School Management System',
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Initialize Firebase
  // For web, we need to initialize differently
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCIVy20Gb4nj5sCa-gH4TOFIIsBw8mlr90",
        appId: "1:446374103543:web:af9f0254002ff4ea5746f2",
        storageBucket: "school-management-system-2b398.firebasestorage.app",
        messagingSenderId: "446374103543",
        projectId: "school-management-system-2b398",
        authDomain: "school-management-system-2b398.firebaseapp.com",
      ),
    );
  } else {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCIVy20Gb4nj5sCa-gH4TOFIIsBw8mlr90",
        appId: "1:446374103543:web:af9f0254002ff4ea5746f2",
        storageBucket: "school-management-system-2b398.firebasestorage.app",
        messagingSenderId: "446374103543",
        projectId: "school-management-system-2b398",
      ),
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MaterialApp(
        title: 'School Management System',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF673AB7)),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
