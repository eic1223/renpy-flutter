import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const RenpyFlutterApp());
}

class RenpyFlutterApp extends StatelessWidget {
  const RenpyFlutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ren\'Py Flutter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}
