import 'package:flutter/material.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import '../api/quote_controller.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'seguimiento_cotizacion.dart';

class CotizacionesPage extends StatefulWidget {
  final String fullname;
  const CotizacionesPage({required this.fullname, super.key});

  @override
  State<CotizacionesPage> createState() => _CotizacionesPageState();
}

class _CotizacionesPageState extends State<CotizacionesPage> {
  List<Map<String, String>> cotizaciones = [];
  String searchText = "";
  DateTime? selectedMonth;
  late TextEditingController searchController;
  bool loading = true;
  // Sort options: 'fecha' or 'numero' (cotizacion). Default: número desc
  String sortBy = 'numero';
  bool sortAsc = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedMonth = DateTime(now.year, now.month);
    searchController = TextEditingController();
    cargarCotizaciones();
  }

  Future<void> cargarCotizaciones() async {
    setState(() => loading = true);
    try {
      final data = await QuoteController.obtenerCotizacionesRealizadas();
      setState(() {
        cotizaciones = List<Map<String, String>>.from(data);
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCotizaciones = cotizaciones.where((cot) {
      final query = searchText.toLowerCase();
      final pertenece =
          cot['vendedor']?.toUpperCase() == widget.fullname.toUpperCase();

      // Filtrar por mes y año seleccionados
      final fechaCot = cot['date'];
      bool coincideFecha = false;
      if (fechaCot != null && fechaCot.isNotEmpty) {
        try {
          // Solo parsea si tiene formato yyyy-MM-dd
          final fecha = DateTime.parse(fechaCot);
          coincideFecha =
              fecha.month == selectedMonth!.month &&
              fecha.year == selectedMonth!.year;
        } catch (_) {
          coincideFecha = false; // Si no se puede parsear, no mostrar
        }
      }
      // Solo mostrar si coincide la fecha y pertenece al usuario
      return pertenece &&
          coincideFecha &&
          ((cot['cotizacion']?.toLowerCase().contains(query) ?? false) ||
              (cot['cliente']?.toLowerCase().contains(query) ?? false) ||
              (cot['producto']?.toLowerCase().contains(query) ?? false) ||
              (cot['linea']?.toLowerCase().contains(query) ?? false) ||
              (cot['modelo']?.toLowerCase().contains(query) ?? false) ||
              (cot['vendedor']?.toLowerCase().contains(query) ?? false));
    }).toList();

    // Create a sorted copy according to sortBy and sortAsc
    final sortedCotizaciones = List<Map<String, String>>.from(
      filteredCotizaciones,
    );
    int compareDates(Map<String, String> a, Map<String, String> b) {
      DateTime da, db;
      try {
        da = a['date'] != null && a['date']!.isNotEmpty
            ? DateTime.parse(a['date']!)
            : DateTime.fromMillisecondsSinceEpoch(0);
      } catch (_) {
        da = DateTime.fromMillisecondsSinceEpoch(0);
      }
      try {
        db = b['date'] != null && b['date']!.isNotEmpty
            ? DateTime.parse(b['date']!)
            : DateTime.fromMillisecondsSinceEpoch(0);
      } catch (_) {
        db = DateTime.fromMillisecondsSinceEpoch(0);
      }
      return da.compareTo(db);
    }

    int compareNumbers(Map<String, String> a, Map<String, String> b) {
      final ra = RegExp(r"(\d+)");
      int na = 0;
      int nb = 0;
      try {
        final ma = ra.allMatches(a['cotizacion'] ?? '');
        if (ma.isNotEmpty) na = int.parse(ma.last.group(0) ?? '0');
      } catch (_) {
        na = 0;
      }
      try {
        final mb = ra.allMatches(b['cotizacion'] ?? '');
        if (mb.isNotEmpty) nb = int.parse(mb.last.group(0) ?? '0');
      } catch (_) {
        nb = 0;
      }
      if (na != nb) return na.compareTo(nb);
      // fallback to string compare
      return (a['cotizacion'] ?? '').compareTo(b['cotizacion'] ?? '');
    }

    sortedCotizaciones.sort((a, b) {
      int res = 0;
      if (sortBy == 'fecha') {
        res = compareDates(a, b);
      } else {
        res = compareNumbers(a, b);
      }
      return sortAsc ? res : -res;
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Cotizaciones Pendientes',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      backgroundColor: Colors.orange[600],
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Column(
              children: [
                SizedBox(height: 20),
                // Top row: filter button (left) and month picker (right)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Filter / Sort button replacing the 'Mes:' label
                      PopupMenuButton<String>(
                        tooltip: 'Filtrar y ordenar',
                        offset: Offset(0, 40),
                        color: Colors.white,
                        onSelected: (value) {
                          setState(() {
                            if (value == 'numero' || value == 'fecha') {
                              sortBy = value;
                            } else if (value == 'asc') {
                              sortAsc = true;
                            } else if (value == 'desc') {
                              sortAsc = false;
                            }
                          });
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'numero',
                            child: Text(
                              'Número de cotización',
                              style: TextStyle(color: Colors.orange[600]),
                            ),
                          ),
                          PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'asc',
                            child: Text(
                              'Ascendente',
                              style: TextStyle(color: Colors.orange[600]),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'desc',
                            child: Text(
                              'Descendente',
                              style: TextStyle(color: Colors.orange[600]),
                            ),
                          ),
                        ],
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.filter_list,
                                color: Colors.orange[600],
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                sortBy == 'fecha' ? 'Fecha' : 'Número',
                                style: TextStyle(
                                  color: Colors.orange[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(
                                sortAsc
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: Colors.orange[600],
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.orange[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          '${selectedMonth!.month.toString().padLeft(2, '0')}/${selectedMonth!.year}',
                        ),
                        onPressed: () async {
                          final now = DateTime.now();
                          final picked = await showMonthPicker(
                            context: context,
                            initialDate: selectedMonth ?? now,
                            firstDate: DateTime(now.year - 3, 1),
                            lastDate: DateTime(now.year + 1, 12),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedMonth = DateTime(
                                picked.year,
                                picked.month,
                              );
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  width: 100,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '${filteredCotizaciones.length}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setState(() {
                        searchText = value;
                      });
                    },
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search, color: Colors.orange[600]),
                      hintText: 'Buscar cotización...',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: searchText.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Colors.orange[600],
                              ),
                              onPressed: () {
                                setState(() {
                                  searchText = "";
                                  searchController.clear();
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: loading
                      ? Center(
                          child: Container(
                            padding: EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white, // Fondo blanco
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 48,
                                  width: 48,
                                  child: CircularProgressIndicator(
                                    color:
                                        Colors.orange[600], // Spinner naranja
                                    strokeWidth: 4,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Consultando cotizaciones...',
                                  style: TextStyle(
                                    color: Colors.orange[600],
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : filteredCotizaciones.isEmpty
                      ? Center(
                          child: Text(
                            'Sin cotizaciones',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: ListView.builder(
                              itemCount: sortedCotizaciones.length,
                              itemBuilder: (context, index) {
                                final cot = sortedCotizaciones[index];
                                return Card(
                                  color: Color(0xFFFFF5F5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: Colors.orange.shade100,
                                    ),
                                  ),
                                  elevation: 2,
                                  margin: EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 4,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Encabezado con cotización y badge
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.description_outlined,
                                              color: Colors.orange[700],
                                              size: 24,
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    cot['cotizacion'] ?? '',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
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
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.orange[50],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.orange.shade200,
                                                ),
                                              ),
                                              child: Text(
                                                'Pendiente',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.orange[700],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 12),

                                        // Información del producto
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.inventory_2,
                                              size: 16,
                                              color: Colors.grey[600],
                                            ),
                                            SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                '${cot['producto'] ?? ''} • ${cot['linea'] ?? ''}',
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),

                                        // Ejes y Modelo
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.settings,
                                              size: 16,
                                              color: Colors.grey[600],
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'Ejes: ${cot['ejes'] ?? ''} • Modelo: ${cot['modelo'] ?? ''}',
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),

                                        // Fecha
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 16,
                                              color: Colors.grey[600],
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'Fecha: ${cot['date'] ?? ''}',
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),

                                        SizedBox(height: 12),

                                        // Botones PDF y Seguimiento
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            // Botón PDF
                                            InkWell(
                                              onTap:
                                                  cot['archivo_pdf'] != null &&
                                                      cot['archivo_pdf']!
                                                          .isNotEmpty
                                                  ? () {
                                                      showDialog(
                                                        context: context,
                                                        barrierDismissible:
                                                            true,
                                                        builder: (context) {
                                                          return Dialog(
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Align(
                                                                  alignment:
                                                                      Alignment
                                                                          .topRight,
                                                                  child: IconButton(
                                                                    icon: Icon(
                                                                      Icons
                                                                          .close,
                                                                    ),
                                                                    onPressed: () =>
                                                                        Navigator.of(
                                                                          context,
                                                                        ).pop(),
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  width:
                                                                      MediaQuery.of(
                                                                        context,
                                                                      ).size.width *
                                                                      0.85,
                                                                  height:
                                                                      MediaQuery.of(
                                                                        context,
                                                                      ).size.height *
                                                                      0.7,
                                                                  child: SfPdfViewer.network(
                                                                    cot['archivo_pdf']!,
                                                                  ),
                                                                ),
                                                                Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    IconButton(
                                                                      icon: Icon(
                                                                        Icons
                                                                            .print,
                                                                      ),
                                                                      onPressed: () async {
                                                                        final response = await http.get(
                                                                          Uri.parse(
                                                                            cot['archivo_pdf']!,
                                                                          ),
                                                                        );
                                                                        if (response.statusCode ==
                                                                            200) {
                                                                          await Printing.layoutPdf(
                                                                            onLayout:
                                                                                (
                                                                                  format,
                                                                                ) async => response.bodyBytes,
                                                                          );
                                                                        }
                                                                      },
                                                                    ),
                                                                    IconButton(
                                                                      icon: Icon(
                                                                        Icons
                                                                            .share,
                                                                      ),
                                                                      onPressed: () async {
                                                                        final response = await http.get(
                                                                          Uri.parse(
                                                                            cot['archivo_pdf']!,
                                                                          ),
                                                                        );
                                                                        if (response.statusCode ==
                                                                            200) {
                                                                          await Printing.sharePdf(
                                                                            bytes:
                                                                                response.bodyBytes,
                                                                            filename:
                                                                                '${cot['cotizacion'] ?? 'cotizacion'}.pdf',
                                                                          );
                                                                        }
                                                                      },
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                      );
                                                    }
                                                  : null,
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 10,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red[50],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.red.shade200,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.picture_as_pdf,
                                                      color: Colors.red[700],
                                                      size: 18,
                                                    ),
                                                    SizedBox(width: 6),
                                                    Text(
                                                      'PDF',
                                                      style: TextStyle(
                                                        color: Colors.red[700],
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            // Botón Seguimiento
                                            InkWell(
                                              onTap: () {
                                                _mostrarDialogoSeguimiento(
                                                  context,
                                                  cot,
                                                );
                                              },
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 10,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange[50],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color:
                                                        Colors.orange.shade200,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.timeline,
                                                      color: Colors.orange[700],
                                                      size: 18,
                                                    ),
                                                    SizedBox(width: 6),
                                                    Text(
                                                      'Seguimiento',
                                                      style: TextStyle(
                                                        color:
                                                            Colors.orange[700],
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoSeguimiento(
    BuildContext context,
    Map<String, String> cotizacion,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.timeline, color: Colors.orange[700], size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Seguimiento de Cotización',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Deseas darle seguimiento a la cotización?',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.description,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cotizacion['cotizacion'] ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                          Text(
                            cotizacion['cliente'] ?? '',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SeguimientoCotizacionPage(cotizacion: cotizacion),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(
                'Continuar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
