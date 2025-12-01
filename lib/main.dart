import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transtools/views/cotizador/seccion2.dart';
import 'package:transtools/views/cotizador/seccion3.dart';
import 'package:transtools/views/cotizador/seccion4.dart';
import 'package:transtools/views/dashboard.dart';
import 'package:transtools/views/login.dart';
import 'package:transtools/views/cotizador/seccion1.dart';
import 'package:transtools/views/cotizaciones_pendientes.dart';
import 'package:transtools/views/listprices.dart';
import 'package:transtools/views/equipmentlist.dart';
import 'package:transtools/views/cotizador/seccion5.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final usuario = prefs.getString('usuario');
  runApp(MyApp(initialRoute: usuario != null ? '/dashboard' : '/'));
}

class MyApp extends StatefulWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

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
      initialRoute: widget.initialRoute, // <-- Usa la ruta inicial correcta
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const Login());

          case "/dashboard":
            return MaterialPageRoute(builder: (_) => const Dashboard());

            case "/listprices":
            return MaterialPageRoute(builder: (_) => ListPricesPage());

              case "/equipments":
              return MaterialPageRoute(builder: (_) => const EquipmentListPage());

            case "/cotizaciones":
            return MaterialPageRoute(builder: (_) => CotizacionesPage(fullname: 'Nombre de usuario'));

          case "/seccion1":
            return MaterialPageRoute(
              builder: (_) => Seccion1(),
              settings: settings, //Esto permite que los argumentos lleguen
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
            case "/seccion5":
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => Seccion5(
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
