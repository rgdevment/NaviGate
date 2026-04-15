import 'package:flutter/material.dart';

void main() {
  runApp(const NavigateApp());
}

class NavigateApp extends StatelessWidget {
  const NavigateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(child: Text('NaviGate')),
      ),
    );
  }
}
