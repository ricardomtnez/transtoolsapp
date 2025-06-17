import 'package:flutter/material.dart';
import 'package:transtools/views/cotizador/seccion2.dart';
import 'package:transtools/views/dashboard.dart';
import 'package:transtools/views/login.dart';
import 'package:transtools/views/cotizador/seccion1.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transtools App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const Login());

          case "/dashboard":
            return MaterialPageRoute(builder: (_) => const Dashboard());

          case "/seccion1":
            return MaterialPageRoute(builder: (_) => const Seccion1());

          case "/seccion2":
            return MaterialPageRoute(builder: (_) => const Seccion2());

          default:
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text('Ruta no encontrada')),
              ),
            );
        }
      },
    );
  }
}
