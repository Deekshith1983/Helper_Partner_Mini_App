import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with graceful error handling so app still runs if Firebase is unconfigured
  try {
    await Firebase.initializeApp();
    debugPrint('✅ [Firebase] Firebase initialized successfully');
  } catch (e) {
    debugPrint('⚠️ [Firebase] Firebase initialization skipped or failed: $e');
  }

  runApp(const HelperPartnerApp());
}
