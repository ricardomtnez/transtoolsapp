import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:transtools/api/quote_controller.dart';
import 'package:transtools/api/login_controller.dart';

class EquipmentListPage extends StatefulWidget {
  const EquipmentListPage({super.key});

  @override
  State<EquipmentListPage> createState() => _EquipmentListPageState();
}

class _EquipmentListPageState extends State<EquipmentListPage> {
  List<Map<String, dynamic>> _grupos = [];
  bool _loading = true;

  List<Map<String, String>> _items = [];
  bool _loadingItems = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchText = '';
  late NumberFormat _currencyFormatter;
  String? _selectedGrupoId;

  @override
  void initState() {
    super.initState();
    _currencyFormatter = NumberFormat.simpleCurrency(locale: 'es_MX');
    _cargarCategorias();
    _searchCtrl.addListener(() {
      setState(() {
        _searchText = _searchCtrl.text;
      });
    });
  }

  Future<void> _cargarCategorias() async {
    try {
      const boardId = 8890947131;
      final grupos = await QuoteController.obtenerCategoriasAdicionales(boardId);
      // Aplicar filtrado por rol y limpiar separadores
      final loginController = LoginController();
      final gruposFiltradosRaw = await loginController.filterGruposByRole(grupos);
      // regex que detecta líneas compuestas solo por guiones, underscores, em-dashes o espacios
  final separatorRegex = RegExp(r'^[\-\_\u2012\u2013\u2014\s]{2,}$');
      final gruposLimpios = gruposFiltradosRaw.where((g) {
        final text = (g['text'] ?? '').toString();
        if (text.trim().isEmpty) return false;
        // eliminar entradas que solo son guiones, underscores o espacios (ej: '-----' o '___')
        if (separatorRegex.hasMatch(text.trim())) return false;
        return true;
      }).toList();

      setState(() {
        _grupos = gruposLimpios;
        _loading = false;
        // No default selection: require the user to choose the equipamiento manually.
        _selectedGrupoId = null;
      });
    } catch (e) {
      setState(() {
        _grupos = [];
        _loading = false;
      });
    }
  }

  Future<void> _cargarItemsParaGrupo(String grupoId) async {
    if (grupoId.isEmpty) return;
    setState(() {
      _loadingItems = true;
      _items = [];
    });
    try {
      final itemsApi = await QuoteController.obtenerAdicionalesPorCategoria(grupoId);
      // Filtrar: excluir 'Separador' y mostrar solo los que tengan estado 'Costeo Aprobado'
      // reuse separator regex to filter out separator rows that may appear as items
  final separatorRegex = RegExp(r'^[\-\_\u2012\u2013\u2014\s]{2,}$');
      final filtered = (itemsApi as List<dynamic>).where((item) {
        try {
          final estado = (item['estado'] ?? '').toString().toLowerCase().trim();
          final nombre = (item['name'] ?? item['nombre'] ?? '').toString();
          // Excluir filas marcadas como separador en estado
          if (estado == 'separador') return false;
          // Excluir filas cuyo nombre sea solo guiones/underscores/espacios
          if (separatorRegex.hasMatch(nombre.trim())) return false;
          // Mostrar sólo los aprobados de costeo
          if (estado.contains('costeo aprobado') || estado == 'costeo aprobado') return true;
          // También aceptar variantes donde aparezca la palabra 'aprob' (aprobado)
          if (estado.contains('aprob')) return true;
          return false;
        } catch (_) {
          return false;
        }
      }).toList();

      setState(() {
        _items = List<Map<String, String>>.from(filtered.map((e) => Map<String, String>.from(e)));
      });
    } catch (e) {
      setState(() {
        _items = [];
      });
    } finally {
      setState(() {
        _loadingItems = false;
      });
    }
  }

  String _formatCurrency(dynamic input) {
    try {
      final val = input is String ? double.tryParse(input.replaceAll('\4', '').replaceAll(',', '')) ?? 0.0 : (input ?? 0.0);
      return _currencyFormatter.format(val);
    } catch (_) {
      return input?.toString() ?? 'N/D';
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _exportarEquipamientosPdf(List<Map<String, String>> items) async {
    final pdf = pw.Document();
    final fecha = DateTime.now();

    // Try to load logo
    pw.ImageProvider? logoImage;
    try {
      final bytesLogo = await rootBundle.load('assets/transtools_logo_white.png');
      logoImage = pw.MemoryImage(bytesLogo.buffer.asUint8List());
    } catch (e) {
      logoImage = null;
    }

    final grupoNombre = _selectedGrupoId != null
        ? (_grupos.firstWhere((g) => g['value']?.toString() == _selectedGrupoId, orElse: () => {'text': ''})['text']?.toString() ?? '')
        : '';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        // Remove global margins so the colored header can stretch edge-to-edge.
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          // Styled header similar to ListPrices: blue bar with logo and white title
          final header = pw.Container(
            color: PdfColors.blue900,
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logoImage != null)
                  pw.Container(width: 160, height: 44, child: pw.Image(logoImage, fit: pw.BoxFit.contain))
                else
                  pw.SizedBox(width: 160, height: 44),
                pw.Text(
                  'LISTA DE EQUIPAMIENTOS',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          );

          final metadata = pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(18, 12, 18, 6),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Fecha: ${fecha.toLocal().toString().split(' ').first}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                if (grupoNombre.isNotEmpty)
                  pw.Text(grupoNombre, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          );

          final content = <pw.Widget>[];
          content.add(pw.SizedBox(height: 6));

          // Header row for the table
          content.add(
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              color: PdfColors.blue900,
              child: pw.Row(
                children: [
                  pw.Expanded(child: pw.Text('Equipamiento', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                  pw.SizedBox(width: 12),
                  pw.Container(width: 110, alignment: pw.Alignment.centerRight, child: pw.Text('Precio Sin IVA', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                  pw.SizedBox(width: 12),
                  pw.Container(width: 110, alignment: pw.Alignment.centerRight, child: pw.Text('Precio Neto', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                ],
              ),
            ),
          );

          // Add each item as a row: Nombre (left) - Precio (right) - Precio Neto (right)
          for (var i = 0; i < items.length; i++) {
            final it = items[i];
            final nombre = it['name'] ?? '';
            final precioRaw = it['precio'] ?? '';

            // Try to parse the raw price into a double (strip $ and thousands separators)
            double? precioBase;
            try {
              final cleaned = precioRaw.toString().replaceAll('\4', '').replaceAll('\ 2', '').replaceAll(r'\$', '').replaceAll(',', '').trim();
              precioBase = double.tryParse(cleaned);
            } catch (_) {
              precioBase = null;
            }

            final precioText = precioBase != null ? _formatCurrency(precioBase) : 'N/D';
            final precioNetoText = precioBase != null ? _formatCurrency(precioBase * 1.16) : 'N/D';

            content.add(
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                decoration: i.isOdd ? pw.BoxDecoration(color: PdfColors.grey100) : null,
                child: pw.Row(
                  children: [
                    pw.Expanded(child: pw.Text(nombre, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
                    pw.SizedBox(width: 12),
                    pw.Container(width: 110, alignment: pw.Alignment.centerRight, child: pw.Text(precioText, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900))),
                    pw.SizedBox(width: 12),
                    pw.Container(width: 110, alignment: pw.Alignment.centerRight, child: pw.Text(precioNetoText, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900))),
                  ],
                ),
              ),
            );
          }

          final nota = pw.Padding(
            padding: const pw.EdgeInsets.only(top: 12),
            child: pw.Text('Precios sujetos a cambio sin previo aviso.', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          );

          return [
            header,
            metadata,
            pw.SizedBox(height: 6),
            pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6), child: pw.Column(children: content)),
            nota,
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'lista_equipamientos.pdf');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          'Lista de Equipamientos',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            tooltip: 'Exportar lista a PDF',
            onPressed: () async {
              // Prepare filtered items similar to the visible list
              final visibles = _items.where((it) {
                if (it['name'] == null) return false;
                if (_searchText.isEmpty) return true;
                return it['name']!.toLowerCase().contains(_searchText.toLowerCase());
              }).toList();
              await _exportarEquipamientosPdf(visibles);
            },
            icon: const Icon(Icons.picture_as_pdf, color: Colors.black),
          ),
        ],
      ),
      backgroundColor: Colors.blue[800],
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Buscar equipamiento...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {
                              _searchText = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
            ),
            // Selector de categoría (abre modal estilizado)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: _grupos.isEmpty
                  ? Container()
                  : GestureDetector(
                      onTap: () async {
                        final selected = await showModalBottomSheet<String>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) {
                            return DraggableScrollableSheet(
                              expand: false,
                              initialChildSize: 0.6,
                              minChildSize: 0.25,
                              maxChildSize: 0.9,
                              builder: (_, controller) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                  ),
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4))),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                        child: Align(alignment: Alignment.centerLeft, child: Text('Selecciona un equipamiento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                                      ),
                                      Expanded(
                                        child: ListView.separated(
                                          controller: controller,
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          itemCount: _grupos.length,
                                          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                                          itemBuilder: (context, i) {
                                            final g = _grupos[i];
                                            final text = g['text']?.toString() ?? '';
                                            final id = g['value']?.toString() ?? '';
                                            return ListTile(
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                              title: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                              trailing: _selectedGrupoId == id ? const Icon(Icons.check, color: Color(0xFF1565C0)) : null,
                                              onTap: () => Navigator.pop(ctx, id),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );

                        if (selected != null && selected.isNotEmpty) {
                          setState(() {
                            _selectedGrupoId = selected;
                          });
                          _cargarItemsParaGrupo(selected);
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          hintText: 'Seleccione el equipamiento',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.transparent)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(_grupos.firstWhere((g) => g['value']?.toString() == _selectedGrupoId, orElse: () => {'text': 'Seleccione el equipamiento'})['text'].toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                            const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                          ],
                        ),
                      ),
                    ),
            ),
            Expanded(
              child: _grupos.isEmpty
                  ? Center(
                      child: Text('No hay categorías disponibles', style: TextStyle(color: Colors.white)),
                    )
                  : _selectedGrupoId == null
                      ? Center(
                          child: Text('Seleccione el equipamiento', style: TextStyle(color: Colors.white)),
                        )
                      : _loadingItems
                          ? const Center(child: CircularProgressIndicator())
                          : Padding(
                          padding: const EdgeInsets.all(16),
                          child: Builder(builder: (context) {
                            final filtered = _items.where((it) {
                              if (it['name'] == null) return false;
                              if (_searchText.isEmpty) return true;
                              return it['name']!.toLowerCase().contains(_searchText.toLowerCase());
                            }).toList();

                            return filtered.isEmpty
                                ? Center(child: Text('No hay equipamientos para esta categoría', style: TextStyle(color: Colors.white)))
                                : ListView.builder(
                                    itemCount: filtered.length,
                                    itemBuilder: (context, index) {
                                      final item = filtered[index];
                                      final nombre = item['name'] ?? '';
                                      final precio = item['precio'] ?? '';
                                      final estado = item['estado'] ?? '';

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        child: Card(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                      const SizedBox(height: 6),
                                                      Text('Estado: $estado', style: const TextStyle(color: Colors.black54)),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Text(_formatCurrency(precio), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1565C0))),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                          }),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
