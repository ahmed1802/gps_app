import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gps_app/screens/home_page.dart';
import 'package:gps_app/screens/send_otp.dart';
import 'package:gps_app/screens/verify_otp.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Change initialRoute to '/' to skip auth, or '/send' to use auth
      initialRoute: '/', // Skip auth for testing (change to '/send' for auth)
      routes: {
        '/': (context) => const HomePage(),
        '/send': (context) => const SendOTP(),
        '/verify': (context) => const VerifyOTP(),
      },
    );
  }
}
