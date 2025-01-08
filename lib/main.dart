import 'package:flutter/material.dart';
import 'screens/loginScreen.dart'; // Import the login screen

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Financial Dashboard",
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(), // Set LoginScreen as the initial screen
    );
  }
}
