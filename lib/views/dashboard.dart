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

class DashboardState extends State<Dashboard> with SingleTickerProviderStateMixin {
  Usuario? _usuario; // Variable para guardar el usuario cargado
  int cotizacionesUsuario = 0;
  List<Map<String, dynamic>> cotizacionesRecientes = [];
  late AnimationController _drawerIconController;

  bool _showWelcome = false;

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
    _drawerIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // Espera un poco y muestra la animación
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _showWelcome = true;
      });
    });
  }

  @override
  void dispose() {
    _drawerIconController.dispose();
    super.dispose();
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
    final ahora = DateTime.now();
    final recientes = cotizaciones.where((cot) {
      if (cot['vendedor']?.toUpperCase() != _usuario!.fullname.toUpperCase()) return false;
      if (cot['date'] == null || cot['date']?.isEmpty == true) return false;
      try {
        final fecha = DateTime.parse(cot['date'] ?? '');
        return fecha.month == ahora.month && fecha.year == ahora.year;
      } catch (_) {
        return false;
      }
    }).toList();
    setState(() {
      cotizacionesUsuario = recientes.length;
      cotizacionesRecientes = recientes.reversed.take(3).toList(); 
    });
  }

  void _handleDrawerChanged(bool isOpened) {
    if (isOpened) {
      _drawerIconController.forward();
    } else {
      _drawerIconController.reverse();
    }
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
      onDrawerChanged: _handleDrawerChanged,
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
              // --- Encabezado con color corporativo ---
              Container(
                width: double.infinity,
                color: const Color(0xFF1565C0),
                padding: const EdgeInsets.only(top: 60, bottom: 24, left: 16, right: 16),
                child: Stack(
                  children: [
                    // Botón cerrar sesión arriba a la derecha
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        tooltip: 'Cerrar sesión',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: const Text(
                                '¿Cerrar sesión?',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF1565C0),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: const Text(
                                '¿Estás seguro que deseas salir de la app?',
                                style: TextStyle(color: Colors.black87),
                              ),
                              actions: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text(
                                        'Cancelar',
                                        style: TextStyle(
                                          color: Color(0xFF1565C0),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 32),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text(
                                        'Cerrar sesión',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.clear();
                            if (!mounted) return;
                            // ignore: use_build_context_synchronously
                            Navigator.pushReplacementNamed(context, "/");
                          }
                        },
                      ),
                    ),
                    // Avatar y nombre centrados
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person, size: 50, color: Color(0xFF1565C0)),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _usuario!.fullname,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // --- Opciones del Drawer ---
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.receipt_long, color: Color(0xFF1565C0)),
                      title: const Text('Cotizador'),
                      splashColor: Colors.blue[100],
                      onTap: () {
                        Navigator.pushNamed(context, "/seccion1");
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.list_alt, color: Color(0xFF1565C0)),
                      title: const Text('Lista de Precios'),
                      splashColor: Colors.blue[100],
                      onTap: () {
                        Navigator.pushNamed(context, "/listprices");
                      },
                    ),
                  ],
                ),
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
        ),
      ),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: AnimatedIcon(
              icon: AnimatedIcons.menu_arrow,
              progress: _drawerIconController,
              color: Colors.white,
            ),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: const Text(""),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.blue[800],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: AnimatedOpacity(
              opacity: _showWelcome ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 700),
              child: AnimatedSlide(
                offset: _showWelcome ? Offset.zero : const Offset(0, 0.2),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOut,
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
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        'assets/transtools_logo_white.png',
                        width: 150,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long, color: Colors.blue[800], size: 32),
                              const SizedBox(width: 8),
                              const Text(
                                "Cotizaciones",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // ANIMATED COUNTER
                          TweenAnimationBuilder<int>(
                            tween: IntTween(begin: 0, end: cotizacionesUsuario),
                            duration: const Duration(milliseconds: 800),
                            builder: (context, value, child) => Text(
                              "$value",
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          // BOTÓN NUEVA COTIZACIÓN
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, "/seccion1");
                            },
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text(
                              "Nueva Cotización",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[800],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              elevation: 2,
                            ),
                          ),
                          const SizedBox(height: 15),
                          // TABLA MEJORADA
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              children: [
                                // Encabezado con fondo gris claro y bordes arriba redondeados
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F5F5),
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(vertical: 10),
                                          child: Text(
                                            "Cotización",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(vertical: 10),
                                          child: Text(
                                            "Fecha",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Aquí van las filas animadas y alternas
                                ...cotizacionesRecientes.asMap().entries.map((entry) {
                                  final i = entry.key;
                                  final cot = entry.value;
                                  final isEven = i % 2 == 0;
                                  return TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: 1),
                                    duration: Duration(milliseconds: 400 + i * 100),
                                    builder: (context, opacity, child) => Opacity(
                                      opacity: opacity,
                                      child: child,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isEven ? Colors.white : const Color(0xFFF8FAFB),
                                        borderRadius: i == cotizacionesRecientes.length - 1
                                            ? const BorderRadius.vertical(bottom: Radius.circular(16))
                                            : BorderRadius.zero,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              child: Text(
                                                cot['cotizacion'] ?? '',
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 8),
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
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
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
        ),
      ),
    );
  }
}
