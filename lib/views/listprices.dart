import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:transtools/api/quote_controller.dart';
import 'package:transtools/api/login_controller.dart';

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
  String? _selectedLinea;
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
      _selectedLinea = null;
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
        _selectedLinea = null;
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
        final id = modelo['value'] ?? '';
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

      // Consulta los precios secuencialmente para poder actualizar el progreso
      for (var modelo in modelosAprobados) {
        final itemId = modelo['value'] ?? '';
        if (!_preciosProductos.containsKey(itemId)) {
          final precio = await obtenerPrecioConAdicionales(itemId);
          _preciosProductos[itemId] = precio;
        }
        setState(() {
          _progresoActual++;
        });
      }

      setState(() {
        _modelos = modelosAprobados;
        _loadingModelos = false;
        _cargandoPrecios = false;
        if (_progresoActual > _progresoTotal) _progresoActual = _progresoTotal;
        _lineasUnicas = _modelos.map((m) => m['linea'] ?? '').toSet().toList()..removeWhere((l) => l.isEmpty);
        _selectedLinea = null;
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
        final id = modelo['value'] ?? '';
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
        final itemId = modelo['value'] ?? '';
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _cargandoLineas
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 2.8,
                        ),
                        itemCount: _lineasUnicas.length,
                        itemBuilder: (context, idx) {
                          final linea = _lineasUnicas[idx];
                          final selected = _selectedLinea == linea;
                          return ChoiceChip(
                            label: Text(
                              linea,
                              style: TextStyle(
                                color: selected ? Colors.white : Colors.blue[900], 
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            selected: selected,
                            onSelected: (value) async {
                              setState(() {
                                _selectedLinea = selected ? null : linea;
                                _loadingModelos = true;
                              });
                              if (_selectedLinea != null) {
                                final modelos = await QuoteController.obtenerModelosPorGrupoSinFiltros(_grupos[_tabController.index]['value']);
                                final filtrados = modelos.where((m) => m['linea'] == _selectedLinea && _esAprobado(m)).toList();
                                final futures = filtrados.map((modelo) async {
                                  final itemId = modelo['value'] ?? '';
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
                                setState(() {
                                  _modelos = [];
                                  _preciosProductos.clear();
                                  _loadingModelos = false;
                                });
                              }
                            },
                            selectedColor: Colors.orange[700], // Color de fondo cuando está seleccionado
                            backgroundColor: Colors.white,      // Fondo blanco cuando no está seleccionado
                            side: BorderSide(
                              color: selected ? Colors.orange[700]! : Colors.blue[900]!, // Borde naranja o azul oscuro
                              width: selected ? 2 : 1,
                            ),
                            elevation: selected ? 4 : 0,
                            shadowColor: Colors.orange[100],
                            labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledColor: Colors.grey[300],
                          );
                        },
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
                            _progresoTotal > 0
                              ? 'Consultando precios... ($_progresoActual de $_progresoTotal)'
                              : 'Consultando Precios...',
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
                            final String itemId = item['value'] ?? '';
                            final precio = _preciosProductos[itemId];

                            return Container(
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
                                  Text(
                                    'N° ${index + 1}',
                                    style: const TextStyle(
                                      color: Color(0xFF1565C0),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    item['producto'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Línea: ${item['linea'] ?? ''}',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 20,
                                    ),
                                  ),
                                  Text(
                                    'Ejes: ${item['ejes'] ?? ''}',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          precio != null
                                            ? 'Precio: ${_formatCurrency(precio)}'
                                            : 'Consultando precio...',
                                          style: TextStyle(
                                            color: Color(0xFF1565C0),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
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
                                          child: Text(
                                            'APROBADO',
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
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

