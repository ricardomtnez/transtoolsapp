import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:transtools/views/cotizador/seccion2.dart';
import 'package:transtools/views/cotizador/seccion3.dart';
import 'package:transtools/views/cotizador/seccion4.dart';
import 'package:transtools/views/dashboard.dart';
import 'package:transtools/views/login.dart';
import 'package:transtools/views/cotizador/seccion1.dart';
import 'package:transtools/views/cotizaciones.dart';
import 'package:transtools/views/listprices.dart';

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

            case "/listprices":
            return MaterialPageRoute(builder: (_) => ListPricesPage());

            case "/cotizaciones":
            return MaterialPageRoute(builder: (_) => CotizacionesPage(fullname: 'Nombre de usuario'));

          case "/seccion1":
            return MaterialPageRoute(
              builder: (_) => Seccion1(),
              settings: settings, // <-- Esto permite que los argumentos lleguen
            );

          case "/seccion2":
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => Seccion2(
                cotizacion: args['cotizacion'],
                modeloNombre: args['modeloNombre'],
                modeloValue: args['modeloValue'],
                configuracionProducto: args['configuracionProducto'],
              ),
            );

          case "/seccion3":
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => Seccion3(cotizacion: args['cotizacion']),
            );

          case "/seccion4":
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => Seccion4(
                cotizacion: args['cotizacion'],
                usuario: args['usuario'],
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
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('es', 'MX'), // Español México
        const Locale('en', 'US'), // Inglés
      ],
    );
  }
}
