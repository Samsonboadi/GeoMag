import 'package:flutter/material.dart';
import 'screens/projects_screen.dart';

class GeoMagApp extends StatelessWidget {
  const GeoMagApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const ProjectsScreen(),
    );
  }
}
