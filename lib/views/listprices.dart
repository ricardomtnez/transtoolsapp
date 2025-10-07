import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:transtools/api/quote_controller.dart';
import 'package:transtools/api/login_controller.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;

class ListPricesPage extends StatefulWidget {
  const ListPricesPage({super.key});

  @override
  State<ListPricesPage> createState() => _ListPricesPageState();
}

class _ListPricesPageState extends State<ListPricesPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _grupos = [];
  late TabController _tabController;
  bool _loading = true;

  List<Map<String, String>> _modelos = [];
  bool _loadingModelos = false;

  // Mapa para almacenar los precios obtenidos
  final Map<String, double> _preciosProductos = {};
  int _progresoActual = 0;
  int _progresoTotal = 0;
  bool _cargandoPrecios = false;

  final ScrollController _scrollController = ScrollController(); 

  // ignore: unused_field
  String _searchText = '';
  Timer? _searchDebounce;
  late NumberFormat _currencyFormatter;
  String _selectedLinea = '';
  List<String> _lineasUnicas = [];
  final Map<String, List<String>> _lineasPorGrupo = {};
  bool _cargandoLineas = true; // Agrega este flag
  bool _sinGruposDisponibles = false;

  // ...existing code...

  @override
  void initState() {
    super.initState();
    _currencyFormatter = NumberFormat.simpleCurrency(locale: 'es_MX');
    cargarGruposYLineas();

    // Debounce listener for search field
    _searchController.addListener(() {
      if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 300), () {
        setState(() {
          _searchText = _searchController.text;
        });
      });
    });
  }

  // Helper para determinar si un modelo está aprobado (exactamente 'APROBADO')
  bool _esAprobado(Map m) {
    return (m['estado'] ?? '').toString().toUpperCase() == 'APROBADO';
  }

  Future<void> cargarGruposYLineas() async {
    final grupos = await QuoteController.obtenerGrupos(4863963204);

  // Delega el filtrado al LoginController (que ya maneja roles)
    final loginController = LoginController();
    final gruposFiltrados = await loginController.filterGruposByRole(grupos);

  // debug temporal eliminado

    if (gruposFiltrados.isEmpty) {
      setState(() {
        _sinGruposDisponibles = true;
        _loading = false;
      });
      return;
    }

      setState(() {
      _grupos = gruposFiltrados;
      _tabController = TabController(length: _grupos.length, vsync: this);
      _loading = false;
      _selectedLinea = '';
      _modelos = [];
      _preciosProductos.clear();
      _lineasUnicas = [];
      _lineasPorGrupo.clear();
      _cargandoLineas = true;
    });

    // Consulta todos los modelos de los grupos en paralelo
    final futures = gruposFiltrados.map((grupo) =>
      QuoteController.obtenerModelosPorGrupoSinFiltros(grupo['value'])
    ).toList();

    final resultados = await Future.wait(futures);

    for (int i = 0; i < gruposFiltrados.length; i++) {
      final modelos = resultados[i];
      // Solo consideramos líneas de modelos aprobados para la lista de filtros
  final aprobados = modelos.where((m) => _esAprobado(m)).toList();
  _lineasPorGrupo[gruposFiltrados[i]['value']] = aprobados.map((m) => m['linea'] ?? '').toSet().toList()..removeWhere((l) => l.isEmpty);
    }

    setState(() {
  _lineasUnicas = _lineasPorGrupo[_grupos[0]['value']] ?? [];
      _cargandoLineas = false;
    });

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _selectedLinea = '';
        _modelos = [];
        _preciosProductos.clear();
        _lineasUnicas = _lineasPorGrupo[_grupos[_tabController.index]['value']] ?? [];
      });
    });
  }

  // Cuando el usuario seleccione el grupo, consulta solo las líneas únicas del grupo seleccionado
  Future<void> cargarLineasPorGrupo(String grupoId) async {
    final modelos = await QuoteController.obtenerModelosPorGrupoSinFiltros(grupoId);
    // Solo incluir líneas de modelos que estén exactamente en estado 'APROBADO'
    final aprobados = modelos.where((m) => _esAprobado(m)).toList();
    setState(() {
      _lineasUnicas = aprobados.map((m) => m['linea'] ?? '').toSet().toList()..removeWhere((l) => l.isEmpty);
    });
  }

  // Modifica cargarModelosPorGrupo para mostrar progreso:
  Future<void> cargarModelosPorGrupoConPrecios(String grupoId) async {
    setState(() {
      _loadingModelos = true;
      _cargandoPrecios = true;
      _progresoActual = 0;
      _progresoTotal = 0;
      _preciosProductos.clear();
    });
    try {
      final modelos = await QuoteController.obtenerModelosPorGrupoSinFiltros(grupoId);
      // Filtramos SOLO modelos aprobados: así no mostramos ni calculamos precios para no aprobados
      final modelosAprobados = modelos.where((m) => _esAprobado(m)).toList();
      _progresoTotal = modelosAprobados.length;

      // Prefill precios desde la respuesta de modelos aprobados si incluyen 'precio' o 'subtotal'
      for (var modelo in modelosAprobados) {
        final id = (modelo['value'] ?? '').toString();
        double? p;
        if (modelo.containsKey('precio') && (modelo['precio']?.toString().isNotEmpty ?? false)) {
          p = double.tryParse(modelo['precio'].toString().replaceAll('\$', '').replaceAll(',', ''));
        } else if (modelo.containsKey('subtotal') && (modelo['subtotal']?.toString().isNotEmpty ?? false)) {
          p = double.tryParse(modelo['subtotal'].toString().replaceAll('\$', '').replaceAll(',', ''));
        }
        if (p != null) {
          _preciosProductos[id] = p;
          // consider prefills as progress
          _progresoActual++;
        }
      }

      // Consulta los precios en paralelo pero actualiza el progreso conforme llegan
      // Limitar concurrencia: ejecutamos en batches para no saturar la API
      const int batchSize = 6;
      final pendientesIds = <String>[];
      for (var modelo in modelosAprobados) {
        final itemId = (modelo['value'] ?? '').toString();
        if (_preciosProductos.containsKey(itemId)) continue;
        pendientesIds.add(itemId);
      }

      for (var i = 0; i < pendientesIds.length; i += batchSize) {
        final batch = pendientesIds.skip(i).take(batchSize).toList();
        final batchFutures = batch.map((itemId) {
          return obtenerPrecioConAdicionales(itemId).then((precio) {
            setState(() {
              _preciosProductos[itemId] = precio;
              _progresoActual++;
              if (_progresoActual > _progresoTotal) _progresoActual = _progresoTotal;
            });
          }).catchError((e) {
            setState(() {
              _progresoActual++;
              if (_progresoActual > _progresoTotal) _progresoActual = _progresoTotal;
            });
          });
        }).toList();

        await Future.wait(batchFutures);
        // pequeña pausa opcional para evitar picos (puedes ajustar o quitar)
        await Future.delayed(const Duration(milliseconds: 50));
      }

      setState(() {
        _modelos = modelosAprobados;
        _loadingModelos = false;
        _cargandoPrecios = false;
        if (_progresoActual > _progresoTotal) _progresoActual = _progresoTotal;
        _lineasUnicas = _modelos.map((m) => m['linea'] ?? '').toSet().toList()..removeWhere((l) => l.isEmpty);
  _selectedLinea = '';
      });
    } catch (e) {
      setState(() {
        _modelos = [];
        _preciosProductos.clear();
        _loadingModelos = false;
        _cargandoPrecios = false;
      });
    }
  }

  Future<void> cargarModelosPorGrupo(String grupoId) async {
    setState(() {
      _loadingModelos = true;
    });
    try {
      final modelos = await QuoteController.obtenerModelosPorGrupoSinFiltros(grupoId);
      // Mantener solo aprobados
  final modelosAprobados = modelos.where((m) => _esAprobado(m)).toList();
      setState(() {
        _modelos = modelosAprobados;
        _loadingModelos = false;
      });

      // Prefill precios desde la respuesta de modelos si incluyen 'precio' o 'subtotal'
      for (var modelo in modelosAprobados) {
        final id = (modelo['value'] ?? '').toString();
        double? p;
        if (modelo.containsKey('precio') && (modelo['precio']?.toString().isNotEmpty ?? false)) {
          p = double.tryParse(modelo['precio'].toString().replaceAll('\$', '').replaceAll(',', ''));
        } else if (modelo.containsKey('subtotal') && (modelo['subtotal']?.toString().isNotEmpty ?? false)) {
          p = double.tryParse(modelo['subtotal'].toString().replaceAll('\$', '').replaceAll(',', ''));
        }
        if (p != null) {
          _preciosProductos[id] = p;
        }
      }

      // Ahora consulta los precios en segundo plano
      for (var modelo in modelosAprobados) {
  final itemId = (modelo['value'] ?? '').toString();
        if (!_preciosProductos.containsKey(itemId)) {
          obtenerPrecioConAdicionales(itemId).then((precio) {
            setState(() {
              _preciosProductos[itemId] = precio;
            });
          });
        }
      }
    } catch (e) {
      setState(() {
        _modelos = [];
        _loadingModelos = false;
      });
    }
  }

  // Método para formatear el precio
  String _formatCurrency(double amount) {
    try {
      return _currencyFormatter.format(amount);
    } catch (e) {
      return '\$${amount.toStringAsFixed(2)}';
    }
  }

  Future<double> obtenerPrecioConAdicionales(String itemId) async {
    final idProducto = int.tryParse(itemId) ?? 0;
    // 1. Obtener datos base
    final precioData = await QuoteController.obtenerPrecioProducto(idProducto);
    // Normalizamos el valor que devuelve QuoteController (precio o subtotal)
    double subtotal = 0.0;
    if (precioData['subtotal'] != null) {
      subtotal = (precioData['subtotal'] is double)
          ? precioData['subtotal'] as double
          : double.tryParse(precioData['subtotal'].toString()) ?? 0.0;
    } else if (precioData['precio'] != null) {
      subtotal = (precioData['precio'] is double)
          ? precioData['precio'] as double
          : double.tryParse(precioData['precio'].toString()) ?? 0.0;
    }

  // returning PRECIO FIJO SIN IVA

    // Retornamos directamente el PRECIO FIJO SIN IVA (sin adicionales ni IVA)
    return subtotal;
  }

  @override
  void dispose() {
  if (!_loading) _tabController.dispose();
  _searchDebounce?.cancel();
  _searchController.removeListener(() {});
  _searchController.dispose();
  _scrollController.dispose(); 
    super.dispose();
  }

  Future<void> _exportarListaPreciosPdf(List modelos) async {
    final pdf = pw.Document();

    final nombreGrupo = (_grupos.isNotEmpty && _tabController.index >= 0 && _tabController.index < _grupos.length)
        ? (_grupos[_tabController.index]['text'] ?? '')
        : '';
    final fecha = DateTime.now();

    // Try to load logo
    pw.ImageProvider? logoImage;
    try {
      final bytesLogo = await rootBundle.load('assets/transtools_logo_white.png');
      logoImage = pw.MemoryImage(bytesLogo.buffer.asUint8List());
    } catch (e) {
      logoImage = null;
    }

    // tableData removed: table will be built manually to allow per-linea coloring

pdf.addPage(
  pw.MultiPage(
    pageFormat: PdfPageFormat.letter.landscape,
    margin: pw.EdgeInsets.zero,
    build: (pw.Context context) {
      // Header
      final header = pw.Container(
        color: PdfColors.blue900,
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (logoImage != null)
              pw.Container(width: 160, height: 44, child: pw.Image(logoImage, fit: pw.BoxFit.contain))
            else
              pw.SizedBox(width: 160, height: 44),
            pw.Text(
              'LISTA DE PRECIOS',
              style: pw.TextStyle(color: PdfColors.white, fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      );

      // Metadata
      final metadata = pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(18, 18, 18, 6),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Fecha: ${fecha.toLocal().toString().split(' ').first}',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            if (nombreGrupo.isNotEmpty)
              pw.Text(
                nombreGrupo,
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
          ],
        ),
      );

      // Preparar los datos de la tabla (agregamos columna Precio + IVA)
      final tableData = List<List<String>>.generate(
        modelos.length,
        (i) {
          final item = modelos[i];
          final codigo = item['producto']?.toString() ?? '';
          final linea = item['linea']?.toString() ?? '';
          final descripcion = item['descripcion']?.toString() ?? '';
          final id = item['value']?.toString() ?? '';

          // Precio base
          final precioBase = _preciosProductos[id];
          final precio = precioBase != null ? _formatCurrency(precioBase) : 'N/D';

          // Precio con IVA
          final precioConIva = precioBase != null ? _formatCurrency(precioBase * 1.16) : 'N/D';

          return [
            codigo,
            linea,
            descripcion,
            precio,
            precioConIva,
          ];
        },
      );

      // Tabla final (5 columnas ahora)
      final table = pw.TableHelper.fromTextArray(
        headers: ['Código', 'Línea', 'Descripción', 'Precio Sin IVA', 'Precio Neto'],
        data: tableData,
        headerDecoration: pw.BoxDecoration(color: PdfColors.blue900),
        headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
        cellStyle: pw.TextStyle(fontSize: 9),
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.8),
        cellAlignments: {
          0: pw.Alignment.center,  // Código
          1: pw.Alignment.center,  // Línea
          2: pw.Alignment.centerLeft,  // Descripción
          3: pw.Alignment.center, // Precio
          4: pw.Alignment.center, // Precio + IVA
        },
        columnWidths: {
          0: const pw.FixedColumnWidth(118),  // Código
          1: const pw.FixedColumnWidth(90), // Línea
          2: const pw.FlexColumnWidth(1),    // Descripción
          3: const pw.FixedColumnWidth(80),  // Precio
          4: const pw.FixedColumnWidth(100), // Precio + IVA
        },
        oddRowDecoration: pw.BoxDecoration(color: PdfColors.grey100),
      );

      // Nota final
      final nota = pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(18, 6, 18, 18),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(height: 12),
            pw.Divider(),
            pw.SizedBox(height: 6),
            pw.Text(
              'Precios sujetos a cambio sin previo aviso. Consulte disponibilidad con su representante de ventas.',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
      );

      return [
        header,
        metadata,
        pw.SizedBox(height: 6),
        pw.Padding(padding: const pw.EdgeInsets.fromLTRB(18, 0, 18, 0), child: table),
        nota,
      ];
    },
  ),
);

    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'lista_precios.pdf');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_sinGruposDisponibles) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lista de Precios'),
        ),
        body: const Center(
          child: Text('No hay grupos disponibles para tu rol.'),
        ),
      );
    }

    // Filtrar modelos para mostrar solo aprobados y por búsqueda
    final modelosFiltrados = _modelos.where((item) {
      if (!_esAprobado(item)) return false;

      if (_searchText.isEmpty) return true;
      final nombre = (item['producto'] ?? '').toString().toLowerCase();
      return nombre.contains(_searchText.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.blue[800],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          automaticallyImplyLeading: true,
          centerTitle: true,
          title: const Text(
            "Lista de Precios",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.blue[800],
            unselectedLabelColor: Colors.black54,
            indicatorColor: Colors.blue[800],
            tabs: _grupos.map((g) => Tab(text: g['text'])).toList(),
          ),
          actions: [
            IconButton(
              tooltip: 'Buscar Remolque',
              onPressed: () async {
                // Open searchable modal to pick a group
                final TextEditingController groupSearch = TextEditingController();
                final selectedGroupId = await showModalBottomSheet<String>(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (ctx) {
                    return DraggableScrollableSheet(
                      expand: false,
                      initialChildSize: 0.6,
                      minChildSize: 0.25,
                      maxChildSize: 0.95,
                      builder: (_, controller) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          child: StatefulBuilder(
                            builder: (contextSheet, setStateSheet) {
                              final query = groupSearch.text.trim().toLowerCase();
                              final filtered = query.isEmpty
                                  ? _grupos
                                  : _grupos.where((g) {
                                      final text = (g['text'] ?? '').toString().toLowerCase();
                                      final value = (g['value'] ?? '').toString().toLowerCase();
                                      return text.contains(query) || value.contains(query);
                                    }).toList();

                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Container(
                                      width: 40,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: TextField(
                                      controller: groupSearch,
                                      decoration: InputDecoration(
                                        hintText: 'Buscar Remolque...',
                                        prefixIcon: const Icon(Icons.search),
                                        suffixIcon: groupSearch.text.isNotEmpty
                                            ? IconButton(icon: const Icon(Icons.clear), onPressed: () { groupSearch.clear(); setStateSheet(() {}); })
                                            : null,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        filled: true,
                                        fillColor: Colors.grey[100],
                                      ),
                                      onChanged: (_) => setStateSheet(() {}),
                                    ),
                                  ),
                                  Expanded(
                                    child: ListView.separated(
                                      controller: controller,
                                      itemCount: filtered.length,
                                      // ignore: unnecessary_underscores
                                      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                                      itemBuilder: (contextList, i) {
                                        final g = filtered[i];
                                        final gid = g['value']?.toString() ?? '';
                                        final gtext = g['text']?.toString() ?? '';
                                        return ListTile(
                                          title: Text(gtext, style: const TextStyle(fontWeight: FontWeight.w600)),
                                          onTap: () => Navigator.pop(ctx, gid),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );

                if (selectedGroupId != null && selectedGroupId.isNotEmpty) {
                  // find index
                  final idx = _grupos.indexWhere((g) => (g['value']?.toString() ?? '') == selectedGroupId);
                  if (idx >= 0 && idx < _grupos.length) {
                    // switch tab and load models
                    _tabController.animateTo(idx);
                    setState(() {
                      _selectedLinea = '';
                      _modelos = [];
                      _preciosProductos.clear();
                      _loadingModelos = true;
                    });
                    await cargarModelosPorGrupoConPrecios(selectedGroupId);
                  }
                }
              },
              icon: const Icon(Icons.search, color: Colors.black),
            ),
            IconButton(
              tooltip: 'Exportar lista a PDF',
              onPressed: () async {
                await _exportarListaPreciosPdf(modelosFiltrados);
              },
              icon: const Icon(Icons.picture_as_pdf, color: Colors.black),
            ),
          ],
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar modelo...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchText = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchText = value;
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: _cargandoLineas
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              // open bottom sheet to select line
                              final selected = await showModalBottomSheet<String>(
                                context: context,
                                backgroundColor: Colors.transparent,
                                isScrollControlled: true,
                                builder: (ctx) {
                                  return DraggableScrollableSheet(
                                    expand: false,
                                    initialChildSize: 0.5,
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
                                              child: Container(
                                                width: 40,
                                                height: 4,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[300],
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              child: Text('Seleccione una linea', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                            ),
                                            Expanded(
                                              child: ListView.separated(
                                                controller: controller,
                                                itemCount: _lineasUnicas.length + 1,
                                                separatorBuilder: (_, _) => Divider(height: 1, color: Colors.grey[200]),
                                                itemBuilder: (context, i) {
                                                  if (i == 0) {
                                                    return ListTile(
                                                      title: const Text('Todas las líneas', style: TextStyle(fontWeight: FontWeight.w600)),
                                                      onTap: () => Navigator.pop(ctx, ''),
                                                    );
                                                  }
                                                  final l = _lineasUnicas[i - 1];
                                                  return ListTile(
                                                    title: Text(l, style: TextStyle(fontWeight: FontWeight.w600)),
                                                    onTap: () => Navigator.pop(ctx, l),
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

                              if (selected != null) {
                                setState(() {
                                  _selectedLinea = selected;
                                  _loadingModelos = true;
                                });

                                if (_selectedLinea.isNotEmpty) {
                                  final modelos = await QuoteController.obtenerModelosPorGrupoSinFiltros(_grupos[_tabController.index]['value']);
                                  final filtrados = modelos.where((m) => m['linea'] == _selectedLinea && _esAprobado(m)).toList();
                                  final futures = filtrados.map((modelo) async {
                                    final itemId = (modelo['value'] ?? '').toString();
                                    final precio = await obtenerPrecioConAdicionales(itemId);
                                    return MapEntry(itemId, precio);
                                  }).toList();
                                  final resultados = await Future.wait(futures);
                                  final precios = <String, double>{};
                                  for (var entry in resultados) {
                                    precios[entry.key] = entry.value;
                                  }
                                  setState(() {
                                    _modelos = filtrados;
                                    _preciosProductos.clear();
                                    _preciosProductos.addAll(precios);
                                    _loadingModelos = false;
                                  });
                                } else {
                                  await cargarModelosPorGrupoConPrecios(_grupos[_tabController.index]['value']);
                                }
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                hintText: 'Seleccione una linea',
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.transparent)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(_selectedLinea.isEmpty ? 'Seleccione una linea' : _selectedLinea, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                                  const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
              ),
              Expanded(
                child: (_loadingModelos || _cargandoPrecios)
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              value: _progresoTotal > 0
                                  ? _progresoActual / _progresoTotal
                                  : null,
                              strokeWidth: 6,
                              color: Colors.white,
                              backgroundColor: Colors.blue[200],
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'Consultando precios...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      thickness: 8,
                      radius: const Radius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: modelosFiltrados.length,
                          itemBuilder: (context, index) {
                            final item = modelosFiltrados[index];
                            final String itemId = (item['value'] ?? '').toString();
                            final precio = _preciosProductos[itemId];
                            final descripcion = (item['descripcion'] ?? '').toString();

                            return InkWell(
                              onTap: () {
                                showModalBottomSheet<void>(
                                  context: context,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                  ),
                                  builder: (ctx) => Padding(
                                    padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
                                    child: DraggableScrollableSheet(
                                      expand: false,
                                      initialChildSize: 0.5,
                                      minChildSize: 0.25,
                                      maxChildSize: 0.9,
                                      builder: (_, controller) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 4,
                                                margin: const EdgeInsets.only(bottom: 12),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[300],
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                              ),
                                              Text(item['producto'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text('Línea: ${item['linea'] ?? ''}', style: const TextStyle(fontSize: 16)),
                                                  Text('Ejes: ${item['ejes'] ?? ''}', style: const TextStyle(fontSize: 16)),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Expanded(
                                                child: SingleChildScrollView(
                                                  child: Text(descripcion.isNotEmpty ? descripcion : 'No hay descripción disponible para este modelo.', style: const TextStyle(fontSize: 14, color: Colors.black87)),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(precio != null ? 'Precio: ${_formatCurrency(precio)}' : 'Precio: Consultando...', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                                              const SizedBox(height: 12),
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton.icon(
                                                  onPressed: () => Navigator.pop(ctx),
                                                  icon: const Icon(Icons.close),
                                                  label: const Text('Cerrar'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.blue[900],
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      // ignore: deprecated_member_use
                                      color: Colors.black.withOpacity(0.12),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
                                padding: const EdgeInsets.all(22),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('N° ${index + 1}', style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 10),
                                    Text(item['producto'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20)),
                                    const SizedBox(height: 6),
                                    Text('Línea: ${item['linea'] ?? ''}', style: const TextStyle(color: Colors.black87, fontSize: 20)),
                                    Text('Ejes: ${item['ejes'] ?? ''}', style: const TextStyle(color: Colors.black87, fontSize: 20)),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            precio != null ? 'Precio: ${_formatCurrency(precio)}' : 'Consultando precio...',
                                            style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold, fontSize: 18),
                                          ),
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            final grupoId = _grupos[_tabController.index]['value'];
                                            final grupoNombre = _grupos[_tabController.index]['text'];
                                            // ignore: unused_local_variable
                                            final productoId = item['value'];
                                            final productoNombre = item['producto'];
                                            final linea = item['linea'];
                                            final ejes = item['ejes'];
                                            // Navegar a la sección de cotización con los datos del grupo y producto
                                            Navigator.pushNamed(
                                              context,
                                              '/seccion1',
                                              arguments: {
                                                'grupo': {
                                                  'value': grupoId,
                                                  'text': grupoNombre,
                                                },
                                                'producto': {
                                                  'value': grupoNombre,
                                                  'text': productoNombre,
                                                  'linea': linea,
                                                  'ejes': ejes,
                                                }
                                              },
                                            );
                                          },
                                          icon: const Icon(Icons.shopping_cart_checkout, size: 18),
                                          label: const Text('Cotizar'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue[900],
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            elevation: 2,
                                            textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_esAprobado(item))
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              // ignore: deprecated_member_use
                                              color: Colors.green.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            child: Text('APROBADO', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1)),
                                          ),
                                        ),
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
    );
  }
}

