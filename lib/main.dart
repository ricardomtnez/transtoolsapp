import 'package:flutter/material.dart';
import 'package:transtools/views/dashboard.dart';
import 'package:transtools/views/login.dart';
import 'package:transtools/views/newquote.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
return MaterialApp(
  title: 'TransTools App',
  theme: ThemeData(
    primarySwatch: Colors.teal,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  ),
  debugShowCheckedModeBanner: false,
  initialRoute: '/', // punto de entrada
  routes: {
    '/': (context) => const Login(),
    '/newquote': (context) => const NewQuote(),
    '/dashboard': (context) => const Dashboard(),
  },
);
  }
}