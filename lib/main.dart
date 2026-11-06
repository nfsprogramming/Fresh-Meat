import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'state/app_state.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase.initializeApp note: $e');
  }
  runApp(const FreshMeatApp());
}

class FreshMeatApp extends StatelessWidget {
  const FreshMeatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'Fresh Meat',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const SplashScreen(),
      ),
    );
  }
}
