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

          case '/dashboard':
            final args = settings.arguments as Map<String, String>;
            return MaterialPageRoute(
              builder: (_) => Dashboard(
                nombre: args['nombre']!,
                departamento: args['departamento']!,
                email: args['email']!,
              ),
            );

          case '/seccion1':
            final args = settings.arguments as Map<String, String>;
            return MaterialPageRoute(
              builder: (_) => Seccion1(
                nombre: args['nombre']!,
                departamento: args['departamento']!,
                email: args['email']!,
              ),
            );

          case '/seccion2':
            //final args = settings.arguments as Map<String, String>;
            return MaterialPageRoute(
              builder: (_) => Seccion2(
                //nombre: args['nombre']!,
               // departamento: args['departamento']!,
                //email: args['email']!,
              ),
            );

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