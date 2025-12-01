import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transtools/api/quote_controller.dart';
import 'package:transtools/models/usuario.dart';
import 'package:transtools/views/cotizaciones_pendientes.dart';
import 'package:transtools/views/autorizar_ordenes_produccion.dart';
import 'package:transtools/views/cotizaciones_canceladas.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key}); // sin parámetros

  @override
  DashboardState createState() => DashboardState();
}

class DashboardState extends State<Dashboard> with SingleTickerProviderStateMixin {
  Usuario? _usuario; // Variable para guardar el usuario cargado
  int cotizacionesUsuario = 0;
  int cotizacionesPendientes = 0;
  int cotizacionesPorAutorizar = 0;
  int cotizacionesCanceladas = 0;
  List<Map<String, dynamic>> cotizacionesRecientes = [];
  late AnimationController _drawerIconController;


  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_ES', null); // Inicializar locale español
    _cargarUsuario();
    _drawerIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // Espera un poco y muestra la animación
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
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
    final mesActual = DateTime.now().month.toString().padLeft(2, '0');
    
    // Filtrar por usuario y mes actual
    final cotizacionesDelUsuario = cotizaciones.where((cot) {
      if (cot['vendedor']?.toUpperCase() != _usuario!.fullname.toUpperCase()) return false;
      if (cot['mes'] == null || cot['mes']?.isEmpty == true) return false;
      return cot['mes'] == mesActual;
    }).toList();
    
    setState(() {
      cotizacionesUsuario = cotizacionesDelUsuario.length;
      // Las pendientes son todas las del mes actual del usuario
      cotizacionesPendientes = cotizacionesDelUsuario.length;
      // Por ahora asignamos valores temporales hasta conectar con la API
      cotizacionesPorAutorizar = 0;
      cotizacionesCanceladas = 0;
      cotizacionesRecientes = cotizacionesDelUsuario.reversed.take(5).toList(); 
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
              colors: [Colors.white, Color(0xFFE3F2FD)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Reusar encabezado simple del Drawer
              Container(
                width: double.infinity,
                color: const Color(0xFF1565C0),
                padding: const EdgeInsets.only(top: 60, bottom: 24, left: 16, right: 16),
                child: Stack(
                  children: [
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
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: IconButton(
                            icon: const Icon(Icons.exit_to_app, color: Colors.white, size: 24),
                            onPressed: () async {
                              final bool? confirmed = await showDialog<bool>(
                                context: context,
                                builder: (dialogCtx) => AlertDialog(
                                  title: const Text('Cerrar sesión'),
                                  content: const Text('¿Deseas cerrar sesión?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(dialogCtx).pop(false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(dialogCtx).pop(true),
                                      child: const Text('Cerrar sesión', style: TextStyle(color: Color(0xFFD32F2F))),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true) {
                                final prefs = await SharedPreferences.getInstance();
                                // Eliminar solo la sesión activa, conservar credenciales guardadas si el usuario eligió "Recuérdame"
                                await prefs.remove('usuario');
                                if (mounted) {
                                  // ignore: use_build_context_synchronously
                                  Navigator.pushReplacementNamed(context, '/');
                                }
                              }
                            },
                            tooltip: 'Cerrar Sesión',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.receipt_long, color: Color(0xFF1565C0)),
                      title: const Text('Cotizar'),
                      onTap: () => Navigator.pushNamed(context, "/seccion1"),
                    ),
                    ExpansionTile(
                      leading: const Icon(Icons.description, color: Color(0xFF1565C0)),
                      title: const Text('Cotizaciones'),
                      childrenPadding: const EdgeInsets.only(left: 24.0),
                      children: [
                        ListTile(
                          leading: const Icon(Icons.pending_actions, color: Color(0xFF1565C0)),
                          title: const Text('Por Autorizar'),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AutorizarOrdenesProduccionPage()),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.schedule, color: Color(0xFF1565C0)),
                          title: const Text('Pendientes'),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CotizacionesPage(fullname: _usuario!.fullname)),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.cancel_outlined, color: Color(0xFF1565C0)),
                          title: const Text('Canceladas'),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CotizacionesCanceladasPage(fullname: _usuario!.fullname)),
                          ),
                        ),
                      ],
                    ),
                    ListTile(
                      leading: const Icon(Icons.list_alt, color: Color(0xFF1565C0)),
                      title: const Text('Lista de Precios'),
                      onTap: () => Navigator.pushNamed(context, "/listprices"),
                    ),
                    ListTile(
                      leading: const Icon(Icons.build_circle, color: Color(0xFF1565C0)),
                      title: const Text('Equipamientos'),
                      onTap: () => Navigator.pushNamed(context, "/equipments"),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text('Versión 1.0.8', style: TextStyle(fontSize: 12, color: Colors.black54)),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: AnimatedIcon(icon: AnimatedIcons.menu_arrow, progress: _drawerIconController, color: const Color(0xFF1565C0)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Image.asset('assets/transtools_logo.png', height: 40, fit: BoxFit.contain),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1565C0),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Stack(
          children: [
            // Cabecera superior con gradiente y formas
            Container(
              height: 240,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color.fromRGBO(6, 120, 207, 1), Color.fromARGB(255, 3, 85, 185)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          // ignore: deprecated_member_use
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), shape: BoxShape.circle),
                          child: Text(
                            _usuario!.fullname.isNotEmpty ? _usuario!.fullname[0].toUpperCase() : 'U',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Hola, ${_usuario!.fullname.split(' ').first}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(DateFormat('dd MMMM', 'es_ES').format(DateTime.now()), style: const TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ),

                      ],
                    ),
                    const SizedBox(height: 18),
                    // Hero stat
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              // ignore: deprecated_member_use
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                                  child: const Icon(Icons.description_outlined, color: Color(0xFF2BB0E6)),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Cotizaciones este mes', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    TweenAnimationBuilder<int>(
                                      tween: IntTween(begin: 0, end: cotizacionesUsuario),
                                      duration: const Duration(milliseconds: 900),
                                      builder: (context, val, child) => Text(val.toString(), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () => Navigator.pushNamed(context, '/seccion1'),
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                            child: const Icon(Icons.add, color: Color(0xFF2BB0E6)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Cuerpo blanco con tarjetas sobresalientes
            DraggableScrollableSheet(
              initialChildSize: 0.62,
              minChildSize: 0.55,
              maxChildSize: 0.95,
              builder: (context, scrollController) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      // Resumen en lista compacta (más discreto y funcional)
                      Column(
                        children: [
                          _buildSummaryRow('Pendientes', cotizacionesPendientes.toString(), Icons.access_time_rounded, const Color(0xFF06AED5), () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CotizacionesPage(fullname: _usuario!.fullname)),
                            );
                          }),
                          const SizedBox(height: 10),
                          _buildSummaryRow('Por Autorizar', cotizacionesPorAutorizar.toString(), Icons.check_circle_outline_rounded, const Color(0xFFFFB703), () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AutorizarOrdenesProduccionPage()),
                            );
                          }),
                          const SizedBox(height: 10),
                          _buildSummaryRow('Canceladas', cotizacionesCanceladas.toString(), Icons.cancel_rounded, const Color(0xFFE63946), () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CotizacionesCanceladasPage(fullname: _usuario!.fullname)),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text('Últimas Cotizaciones', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      // Lista de cotizaciones recientes con banda lateral de color
                      ...cotizacionesRecientes.map((cot) {
                        final dateRaw = cot['date'] ?? '';
                        String fechaFormateada = dateRaw;
                        try {
                          final dt = DateTime.parse(dateRaw);
                          fechaFormateada = DateFormat('dd MMM', 'es_ES').format(dt);
                        } catch (_) {}
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            // ignore: deprecated_member_use
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3))],
                          ),
                          child: Row(
                            children: [
                              // Banda lateral
                              Container(width: 6, height: 80, decoration: BoxDecoration(color: const Color(0xFF2BB0E6), borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), bottomLeft: Radius.circular(14)))),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(cot['cotizacion'] ?? 'Sin número', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 6),
                                      Row(children: [const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey), const SizedBox(width: 6), Text(fechaFormateada, style: const TextStyle(color: Colors.grey))]),
                                    ],
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: Icon(Icons.chevron_right_rounded, color: Colors.grey),
                              )
                            ],
                          ),
                        );
                      }),
                      if (cotizacionesRecientes.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(30),
                          alignment: Alignment.center,
                          child: Column(children: [Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]), const SizedBox(height: 12), Text('No hay cotizaciones este mes', style: TextStyle(color: Colors.grey[600]))]),
                        ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  
  // ignore: unused_element
  Widget _buildCompactCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          // ignore: deprecated_member_use
          colors: [color, color.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: color.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  // ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.95),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: int.tryParse(value) ?? 0),
                duration: const Duration(milliseconds: 800),
                builder: (context, animatedValue, child) => Text(
                  animatedValue.toString(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // ignore: unused_element
  Widget _buildHorizontalStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                // ignore: deprecated_member_use
                colors: [color, color.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: int.tryParse(value) ?? 0),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, animatedValue, child) => Text(
                    animatedValue.toString(),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  // ignore: unused_element
  Widget _buildSimpleQuoteCard(String cotizacion, String fecha) {
    String fechaFormateada = '';
    if (fecha.isNotEmpty) {
      try {
        final dt = DateTime.parse(fecha);
        fechaFormateada = DateFormat('dd MMM', 'es_ES').format(dt);
      } catch (_) {
        fechaFormateada = fecha;
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: const Color(0xFF1565C0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: Color(0xFF1565C0),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cotizacion,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      fechaFormateada,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey[400],
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
  
  // Mantener métodos antiguos por compatibilidad
  // ignore: unused_element
  Widget _buildCompactStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: int.tryParse(value) ?? 0),
          duration: const Duration(milliseconds: 800),
          builder: (context, animatedValue, child) => Text(
            animatedValue.toString(),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            // ignore: deprecated_member_use
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  // ignore: unused_element
  Widget _buildTimelineQuoteCard(String cotizacion, String fecha, bool isLast) {
    String fechaFormateada = '';
    if (fecha.isNotEmpty) {
      try {
        final dt = DateTime.parse(fecha);
        fechaFormateada = DateFormat('dd MMM', 'es_ES').format(dt);
      } catch (_) {
        fechaFormateada = fecha;
      }
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Línea de tiempo
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                // ignore: deprecated_member_use
                color: const Color(0xFF1565C0).withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Contenido de la tarjeta
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                // ignore: deprecated_member_use
                color: const Color(0xFF1565C0).withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cotizacion,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fechaFormateada,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  // Mantener el método antiguo por si acaso, pero no se usa
  // ignore: unused_element
  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      builder: (context, opacity, child) => Opacity(
        opacity: opacity,
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: int.tryParse(value) ?? 0),
              duration: const Duration(milliseconds: 800),
              builder: (context, animatedValue, child) => Text(
                animatedValue.toString(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // ignore: unused_element
  Widget _buildQuoteCard(String cotizacion, String fecha) {
    String fechaFormateada = '';
    if (fecha.isNotEmpty) {
      try {
        final dt = DateTime.parse(fecha);
        fechaFormateada = DateFormat('dd MMM', 'es_ES').format(dt);
      } catch (_) {
        fechaFormateada = fecha;
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              cotizacion,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            fechaFormateada,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon, Color color, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          // ignore: deprecated_member_use
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              // ignore: deprecated_member_use
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Resumen', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
