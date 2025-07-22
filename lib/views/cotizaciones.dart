import 'package:flutter/material.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import '../api/quote_controller.dart'; 
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;

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
      for (var item in data) {
        // ignore: avoid_print
        print('Item recibido: $item');
      }
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
      final pertenece = cot['vendedor']?.toUpperCase() == widget.fullname.toUpperCase();

      // Filtrar por mes y año seleccionados
      final fechaCot = cot['date'];
      bool coincideFecha = false;
      if (fechaCot != null && fechaCot.isNotEmpty) {
        try {
          // Solo parsea si tiene formato yyyy-MM-dd
          final fecha = DateTime.parse(fechaCot);
          coincideFecha = fecha.month == selectedMonth!.month && fecha.year == selectedMonth!.year;
        } catch (_) {
          coincideFecha = false; // Si no se puede parsear, no mostrar
        }
      }
      // Solo mostrar si coincide la fecha y pertenece al usuario
      return pertenece && coincideFecha && (
        (cot['cotizacion']?.toLowerCase().contains(query) ?? false) ||
        (cot['producto']?.toLowerCase().contains(query) ?? false) ||
        (cot['linea']?.toLowerCase().contains(query) ?? false) ||
        (cot['modelo']?.toLowerCase().contains(query) ?? false) ||
        (cot['vendedor']?.toLowerCase().contains(query) ?? false)
      );
    }).toList();

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
          'Cotizaciones Realizadas',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      backgroundColor: Colors.blue[800],
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 20),
            // Month Picker Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Mes: ${selectedMonth!.month.toString().padLeft(2, '0')}/${selectedMonth!.year}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue[800],
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
                          selectedMonth = DateTime(picked.year, picked.month);
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
                  prefixIcon: Icon(Icons.search, color: Colors.blue[800]),
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
                          icon: Icon(Icons.clear, color: Colors.blue[800]),
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
                                color: Colors.blue[800], // Spinner azul
                                strokeWidth: 4,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Consultando cotizaciones...',
                              style: TextStyle(
                                color: Colors.blue[800],
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      padding: EdgeInsets.all(10),
                      child: filteredCotizaciones.isEmpty
                          ? Center(
                              child: Text(
                                'Sin cotizaciones',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredCotizaciones.length,
                              itemBuilder: (context, index) {
                                final cot = filteredCotizaciones[index];
                                return Card(
                                  color: Colors.blue[800],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 10,
                                  // ignore: deprecated_member_use
                                  shadowColor: Colors.black.withOpacity(0.25),
                                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          // ignore: deprecated_member_use
                                          color: Colors.black.withOpacity(0.18),
                                          blurRadius: 18,
                                          offset: Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  cot['cotizacion'] ?? '',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  cot['producto'] ?? '',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  cot['linea'] ?? '',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  'Ejes: ${cot['ejes'] ?? ''}',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  'Modelo: ${cot['modelo'] ?? ''}',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  'Fecha: ${cot['date'] ?? ''}',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  'Vendedor: ${cot['vendedor'] ?? ''}',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          GestureDetector(
                                            onTap: cot['archivo_pdf'] != null && cot['archivo_pdf']!.isNotEmpty
                                                ? () {
                                                    showDialog(
                                                      context: context,
                                                      barrierDismissible: true,
                                                      builder: (context) {
                                                        return Dialog(
                                                          child: Column(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              SizedBox(
                                                                width: MediaQuery.of(context).size.width * 0.85,
                                                                height: MediaQuery.of(context).size.height * 0.7,
                                                                child: SfPdfViewer.network(cot['archivo_pdf']!),
                                                              ),
                                                              Row(
                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                children: [
                                                                  IconButton(
                                                                    icon: Icon(Icons.print),
                                                                    onPressed: () async {
                                                                      final response = await http.get(Uri.parse(cot['archivo_pdf']!));
                                                                      if (response.statusCode == 200) {
                                                                        await Printing.layoutPdf(
                                                                          onLayout: (format) async => response.bodyBytes,
                                                                        );
                                                                      }
                                                                    },
                                                                  ),
                                                                  IconButton(
                                                                    icon: Icon(Icons.share),
                                                                    onPressed: () async {
                                                                      final response = await http.get(Uri.parse(cot['archivo_pdf']!));
                                                                      if (response.statusCode == 200) {
                                                                        await Printing.sharePdf(
                                                                          bytes: response.bodyBytes,
                                                                          filename: '${cot['cotizacion'] ?? 'cotizacion'}.pdf',
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
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(Icons.picture_as_pdf, color: Color(0xFFD32F2F), size: 32),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}