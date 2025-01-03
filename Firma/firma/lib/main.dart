import 'package:flutter/material.dart';
import 'screens/WelcomeScreen.dart'; // Import the WelcomeScreen class

void main() {
  runApp(FirmaApp());
}

class FirmaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firma - Surveillance Agricole',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.green,
          accentColor: Colors.orange,
        ).copyWith(secondary: Colors.orange), 
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: Colors.black87, fontSize: 16),
        ),
        cardTheme: CardTheme(
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      home: WelcomeScreen(), // Show the WelcomeScreen first
    );
  }
}
