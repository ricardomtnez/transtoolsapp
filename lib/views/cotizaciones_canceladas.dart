import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CotizacionesCanceladasPage extends StatefulWidget {
  final String fullname;
  const CotizacionesCanceladasPage({required this.fullname, super.key});

  @override
  State<CotizacionesCanceladasPage> createState() => _CotizacionesCanceladasPageState();
}

class _CotizacionesCanceladasPageState extends State<CotizacionesCanceladasPage> {
  List<Map<String, dynamic>> cotizacionesCanceladas = [];
  bool loading = true;
  String searchText = "";
  late TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    _cargarCotizacionesCanceladas();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarCotizacionesCanceladas() async {
    setState(() => loading = true);
    await Future.delayed(const Duration(milliseconds: 400));

    // Datos de ejemplo - reemplazar con llamada real a API/Monday
    cotizacionesCanceladas = [
      {
        'cotizacion': 'COT-2024-001',
        'cliente': 'Transportes del Norte',
        'producto': 'Remolque',
        'modelo': 'REM-500',
        'fecha': DateTime(2024, 10, 15).toIso8601String(),
        'motivoCancelacion': 'Cliente decidió posponer la compra',
        'fechaCancelacion': DateTime(2024, 10, 20).toIso8601String(),
      },
      {
        'cotizacion': 'COT-2024-002',
        'cliente': 'Logística Express',
        'producto': 'Caja refrigerada',
        'modelo': 'CR-300',
        'fecha': DateTime(2024, 9, 10).toIso8601String(),
        'motivoCancelacion': 'Presupuesto fuera de rango',
        'fechaCancelacion': DateTime(2024, 9, 15).toIso8601String(),
      },
      {
        'cotizacion': 'COT-2024-003',
        'cliente': 'Distribuidora Central',
        'producto': 'Remolque',
        'modelo': 'REM-700',
        'fecha': DateTime(2024, 8, 5).toIso8601String(),
        'motivoCancelacion': 'Cliente encontró mejor oferta',
        'fechaCancelacion': DateTime(2024, 8, 12).toIso8601String(),
      },
    ];

    setState(() => loading = false);
  }

  List<Map<String, dynamic>> get _filtradas {
    if (searchText.trim().isEmpty) return cotizacionesCanceladas;
    final query = searchText.toLowerCase();
    return cotizacionesCanceladas.where((cot) {
      return (cot['cotizacion']?.toString().toLowerCase().contains(query) ?? false) ||
          (cot['cliente']?.toString().toLowerCase().contains(query) ?? false) ||
          (cot['producto']?.toString().toLowerCase().contains(query) ?? false) ||
          (cot['modelo']?.toString().toLowerCase().contains(query) ?? false);
    }).toList();
  }

  String _formatFecha(String? fecha) {
    if (fecha == null || fecha.isEmpty) return '';
    try {
      final parsedDate = DateTime.parse(fecha);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return fecha;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cotizaciones Canceladas'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 139, 21, 23),
      body: SafeArea(
        child: Column(
          children: [
            // Barra de búsqueda
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: searchController,
                onChanged: (value) => setState(() => searchText = value),
                decoration: InputDecoration(
                  hintText: 'Buscar por cotización, cliente, producto...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchText.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            searchController.clear();
                            setState(() => searchText = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Lista de cotizaciones canceladas
            Expanded(
              child: loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : _filtradas.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text(
                              'No hay cotizaciones canceladas',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtradas.length,
                          // ignore: unnecessary_underscores
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final cot = _filtradas[index];
                            return Card(
                              color: const Color(0xFFFFF5F5),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.red.shade100),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Encabezado con cotización y estado
                                    Row(
                                      children: [
                                        Icon(Icons.cancel_outlined, color: Colors.red[700]),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                cot['cotizacion'] ?? '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                cot['cliente'] ?? '',
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red[50],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.red.shade200),
                                          ),
                                          child: Text(
                                            'Cancelada',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.red[700],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Información del producto
                                    Row(
                                      children: [
                                        Icon(Icons.inventory_2, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${cot['producto']} • ${cot['modelo']}',
                                          style: TextStyle(color: Colors.grey[700]),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Fechas
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Creada: ${_formatFecha(cot['fecha'])}',
                                          style: TextStyle(color: Colors.grey[700], fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.event_busy, size: 16, color: Colors.red[600]),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Cancelada: ${_formatFecha(cot['fechaCancelacion'])}',
                                          style: TextStyle(
                                            color: Colors.red[700],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Motivo de cancelación
                                    if (cot['motivoCancelacion'] != null && cot['motivoCancelacion'].toString().isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red[50],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.red.shade100),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Icon(Icons.info_outline, size: 16, color: Colors.red[700]),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Motivo de cancelación:',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.red[700],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    cot['motivoCancelacion'] ?? '',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[800],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
