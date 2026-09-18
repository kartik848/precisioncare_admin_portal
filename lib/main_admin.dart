import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_theme.dart';
import 'firebase_options.dart';
import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/report_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/admin/admin_login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Live Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    debugPrint('✓ Live Firebase & Firestore online connected (precision-care-2ab84)');
  } catch (e) {
    debugPrint('Firebase Admin notice: $e');
  }

  runApp(const PrecisionCareAdminApp());
}

class PrecisionCareAdminApp extends StatelessWidget {
  const PrecisionCareAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CatalogProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp(
        title: 'PrecisionCare Admin Portal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AdminLoginScreen(),
      ),
    );
  }
}
