import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() => runApp(const PlaneEscapeApp());

class PlaneEscapeApp extends StatelessWidget {
  const PlaneEscapeApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plane Escape',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}