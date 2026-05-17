import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'app.dart';
import 'services/connectivity_service.dart';
import 'services/database_service.dart';
import 'services/notification_log_service.dart';
import 'services/notification_preferences.dart';
import 'services/privacy_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await DatabaseService.instance.ensureLoaded();
  await NotificationPreferences.instance.ensureLoaded();
  await NotificationLog.instance.ensureLoaded();
  await PrivacyPreferences.instance.ensureLoaded();
  await ConnectivityService.instance.ensureLoaded();

  runApp(const CashBackRewardsApp());
}
