import 'package:flutter/material.dart';

import 'screens/map_screen.dart';

void main() => runApp(const ApuntaDescubreApp());

class ApuntaDescubreApp extends StatelessWidget {
  const ApuntaDescubreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apunta y Descubre',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const MapScreen(),
    );
  }
}
