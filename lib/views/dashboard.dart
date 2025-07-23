import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transtools/api/quote_controller.dart';
import 'package:transtools/models/usuario.dart';
import 'package:transtools/views/cotizaciones.dart';
import 'package:intl/intl.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key}); // sin parámetros

  @override
  DashboardState createState() => DashboardState();
}

class DashboardState extends State<Dashboard> {
  Usuario? _usuario; // Variable para guardar el usuario cargado
  int cotizacionesUsuario = 0;
  List<Map<String, dynamic>> cotizacionesRecientes = [];

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('usuario');
    if (jsonString != null) {
      setState(() {
        _usuario = Usuario.fromJson(jsonString);
      });
      await _contarCotizacionesUsuario(); // <-- Aquí
    }
  }

  Future<void> _contarCotizacionesUsuario() async {
    final cotizaciones = await QuoteController.obtenerCotizacionesRealizadas();
    final recientes = cotizaciones
        .where((cot) => cot['vendedor']?.toUpperCase() == _usuario!.fullname.toUpperCase())
        .toList();
    setState(() {
      cotizacionesUsuario = recientes.length;
      cotizacionesRecientes = recientes.reversed.take(3).toList(); // Últimas 3
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_usuario == null) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(), // Esperando a que cargue el usuario
        ),
      );
    }

    return Scaffold(
      drawer: Drawer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromARGB(255, 233, 227, 227),
                Color.fromARGB(255, 212, 206, 206),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const SizedBox(height: 60),
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _usuario!.fullname,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: const Text('Cotizador'),
                    onTap: () {
                      Navigator.pushNamed(context, "/seccion1");
                    },
                  ),
                ],
              ),
              Column(
                children: [
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      if (!mounted) return;
                      // ignore: use_build_context_synchronously
                      Navigator.pushReplacementNamed(context, "/");
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 35),
                    child: Text(
                      'Versión 1.0',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text(""),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.blue[800],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 0), 
                const Text(
                  "Bienvenido",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _usuario!.fullname,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8), // antes 10
                  child: Image.asset(
                    'assets/transtools_logo_white.png',
                    width: 150, // antes 180
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12), 
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Cotizaciones",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("$cotizacionesUsuario", style: TextStyle(fontSize: 30)),
                      const SizedBox(height: 15),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            "/seccion1",
                            arguments: {
                              "nombre": _usuario!.fullname,
                              "departamento": _usuario!.departamento,
                              "email": _usuario!.email,
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          minimumSize: const Size(100, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Nueva Cotización",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Cotizaciones Recientes",
                        style: TextStyle(fontWeight: FontWeight.bold),
                        
                      ),
                      const SizedBox(height: 10),
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(),
                          1: FlexColumnWidth(),
                        },
                        border: const TableBorder.symmetric(
                          inside: BorderSide(width: 0.5, color: Colors.grey),
                        ),
                        children: [
                          const TableRow(
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text("Cotización", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text("Fecha", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          ...cotizacionesRecientes.map((cot) => TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Text(
                                  cot['cotizacion'] ?? '',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Text(
                                  cot['date'] != null && cot['date']!.isNotEmpty
                                    ? (() {
                                        try {
                                          final fecha = DateTime.parse(cot['date']!);
                                          return DateFormat('dd/MM/yyyy').format(fecha);
                                        } catch (_) {
                                          return cot['date']!;
                                        }
                                      })()
                                    : '',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          )),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          // Navigator.pushNamed(context, "/cotizaciones");
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CotizacionesPage(
                                fullname: _usuario!.fullname,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Ver Más",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
