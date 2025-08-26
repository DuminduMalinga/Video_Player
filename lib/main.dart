import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Video Player',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const WelcomeScreen(),
      builder: (context, child) {
        // Fixed gradient background for all screens
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.pink],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: child,
        );
      },
      routes: {'/home': (context) => const HomeScreen()},
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // gradient visible
      appBar: AppBar(
        title: const Text("Home Screen"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          "Welcome to the Video Player App!",
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
    );
  }
}
