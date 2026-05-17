import 'package:flutter/material.dart';
import 'home_page.dart';
import 'services/user_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final onboardingDone = await UserStorage.isOnboardingComplete();
  runApp(MainApp(onboardingDone: onboardingDone));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key, required this.onboardingDone});

  final bool onboardingDone;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: onboardingDone
          ? const Placeholder() // TODO: replace with main app screen
          : const HomePage(),
    );
  }
}
