import 'package:flutter/material.dart';
import 'package:pareja_play_prueba/screens/home_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Pareja Play',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    height: 30 / 24,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
          foregroundColor: const Color(0xFFFF27A1),
        ),

        backgroundColor: const Color.fromARGB(197, 255, 0, 208),
        body: HomeScreen(),
      ),
    );
  }
}
