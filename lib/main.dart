import 'package:flutter/material.dart';
import 'screens/main_screen.dart'; // 새로 분리된 MainScreen 임포트
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter 프레임워크 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Match Planner',
      theme: ThemeData(
        primaryColor: Colors.blue[50],
        primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue[50],
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: Colors.blue[50],
            minimumSize: Size(200, 60),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: MainScreen(), // MainScreen을 사용
    );
  }
}
