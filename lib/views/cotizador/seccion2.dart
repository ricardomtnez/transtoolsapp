import 'package:flutter/material.dart';
import 'package:transtools/api/quote_controller.dart';
import 'package:transtools/api/login_controller.dart';
import 'package:transtools/models/adicional_seleccionado.dart';
import 'package:transtools/models/cotizacion.dart';
import 'package:intl/intl.dart';

class Seccion2 extends StatefulWidget {
  final String modeloNombre;
  final String modeloValue;
  final String configuracionProducto;
  final Cotizacion cotizacion;

  const Seccion2({
    super.key,
    required this.modeloNombre,
    required this.modeloValue,
    required this.configuracionProducto,
    required this.cotizacion,
  });

  @override
  State<Seccion2> createState() => _Seccion2State();
}

class _Seccion2State extends State<Seccion2> {
  final ScrollController _scrollController = ScrollController();
  Map<String, dynamic> especificaciones = {};

  String? _estadoProducto;
  final Map<String, bool> _expandedMainSections = {
    'Especificaciones Técnicas': true,
    'Adicionales': true,
  };

  final List<Map<String, String>> _gruposAdicionales = [];
  String? _grupoSeleccionadoId;
  final List<Map<String, String>> _itemsDelGrupo = [];
  List<Map<String, String>> _filteredItemsDelGrupo = [];
  final TextEditingController _searchAdicionalesCtrl = TextEditingController();
  final List<String> _adicionalesSeleccionados = [];
  bool _cargandoAdicionales = false;

  final Map<String, int> _cantidadesAdicionales = {};
  final Map<String, double> _preciosAdicionales = {};
  final Map<String, String> _estadosAdicionales = {};

  // Per-row excluded items (ids)
  final Set<String> _excluidos = <String>{};

  // ignore: unused_element
  void _toggleRowExclusion(String id) {
    setState(() {
      // ignore: curly_braces_in_flow_control_structures
      if (_excluidos.contains(id)) _excluidos.remove(id); else _excluidos.add(id);
    });
  }

  bool _adicionalesTileExpanded = true;

  bool _precioCargado = false;
  double _precioProductoConAdicionales = 0.0;

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
    _cargarCategoriasAdicionales();
  }

  Future<void> _cargarUsuario() async {
    const boardId = 9364424510;
    try {
      final grupos = await QuoteController.obtenerGruposEstructura(boardId);
      Map<String, dynamic>? grupoCoincidente;
      try {
        grupoCoincidente = grupos.firstWhere((grupo) {
          final grupoClave = grupo['text']!.toLowerCase().trim();
          final modeloClave = widget.modeloNombre.toLowerCase().trim();
          return grupoClave == modeloClave;
        });
      } catch (e) {
        grupoCoincidente = null;
      }
      if (grupoCoincidente != null) {
        final String grupoId = grupoCoincidente['value']!;
        _cargarFichaTecnica(grupoId, boardId);
      } else {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Grupo no encontrado'),
            content: Text('No se encontró la estructura del modelo: ${widget.modeloNombre}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Error al consultar grupos: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }
  }

  void _cargarFichaTecnica(String grupoId, int boardId) async {
    try {
      final ficha = await QuoteController.obtenerFichaTecnica(grupoId, boardId);
      final Map<String, dynamic> estructura = {};
      for (final item in ficha) {
        final config = item['configuracion'] ?? '';
        final descripcion = item['descripcion'] ?? '';
        estructura[config] = descripcion;
      }
      setState(() {
        especificaciones = {'Estructura': estructura};
      });
      _cargarAdicionales();
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text('Error cargando ficha técnica:\n$e'),
          actions: [
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }
  void _cargarAdicionales() async {
    try {
      setState(() {
        _cargandoAdicionales = true;
      });
      final idItemInt = int.tryParse(widget.modeloValue) ?? 0;
      final adicionales = await QuoteController.obtenerKitsAdicionales(idItemInt);
      setState(() {
        especificaciones['Adicionales de Línea'] = adicionales;
      });
      _cargarPrecioProducto();
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text('Error cargando kits adicionales:\n$e'),
          actions: [
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        _cargandoAdicionales = false;
      });
    }
  }

  void _cargarPrecioProducto() async {
    try {
      final idProducto = int.tryParse(widget.modeloValue) ?? 0;
      final precioData = await QuoteController.obtenerPrecioProducto(idProducto);
      final precio = precioData['precio'] ?? 0.0;
      final estado = precioData['estado'] ?? '';
      setState(() {
        _precioProductoConAdicionales = precio;
        _precioCargado = true;
        _estadoProducto = estado;
        // Persist into the Cotizacion object so subsequent opens reuse data
        try {
          widget.cotizacion.estructura = especificaciones['Estructura'] ?? {};
          widget.cotizacion.adicionalesDeLinea = especificaciones['Adicionales de Línea'] ?? [];
          widget.cotizacion.precioProductoConAdicionales = _precioProductoConAdicionales;
          widget.cotizacion.estadoProducto = _estadoProducto;
          widget.cotizacion.datosCargados = true;
        } catch (_) {
          // ignore errors when persisting optional fields
        }
      });
  // no-op: caching removed to always fetch fresh data
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text('Error cargando el precio del producto:\n$e'),
          actions: [
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _cargarCategoriasAdicionales() async {
    try {
      const boardId = 8890947131;
      final gruposApi = await QuoteController.obtenerCategoriasAdicionales(boardId);
      // Filtrar según rol usando el LoginController (ocultar "PERSONALIZADAS" para Miembro)
      final loginController = LoginController();
      final gruposFiltradosRaw = await loginController.filterGruposByRole(gruposApi);
      setState(() {
        _gruposAdicionales.clear();
        _gruposAdicionales.addAll(
          gruposFiltradosRaw.map<Map<String, String>>((g) {
            return {
              'value': g['value']?.toString() ?? '',
              'text': g['text']?.toString() ?? '',
            };
          }),
        );
      });
    // ignore: empty_catches
    } catch (e) {}
  }

  Future<void> _cargarItemsDelGrupo(String grupoId) async {
    setState(() {
      _cargandoAdicionales = true;
    });
    try {
      final itemsApi = await QuoteController.obtenerAdicionalesPorCategoria(grupoId);
      // Exclude items whose estado is 'Separador'
      final filtered = itemsApi.where((item) {
        final estado = (item['estado'] ?? '').toString().toLowerCase();
        return estado != 'separador';
      }).toList();
      setState(() {
        _itemsDelGrupo.clear();
        _itemsDelGrupo.addAll(List<Map<String, String>>.from(filtered.map((e) => Map<String, String>.from(e))));
        // initialize filtered list to show all when first loaded
        _filteredItemsDelGrupo = List<Map<String, String>>.from(_itemsDelGrupo);
      });
    } finally {
      setState(() {
        _cargandoAdicionales = false;
      });
    }
  }

  @override
  void dispose() {
    _searchAdicionalesCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text(
            'Estructura del Producto',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          centerTitle: true,
        ),
        backgroundColor: Colors.blue[800],
        body: (especificaciones.isEmpty || !_precioCargado)
            ? _buildLoader()
            : Column(
                children: [
                  StepHeaderBar(pasoActual: 2, totalPasos: 4),
                  const SizedBox(height: 14),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          _buildMainSection(
                            title: widget.configuracionProducto,
                            content: especificaciones,
                          ),
                          _buildAdicionalesCarrito(),
                          _buildTotalGeneralCard(),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 140,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                    elevation: 0,
                                  ),
                                  child: const Text('Atrás'),
                                ),
                              ),
                              const SizedBox(width: 32),
                              SizedBox(
                                width: 140,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    // Build estructura by removing any keys explicitly excluded by the user.
                                    final rawEstructura = Map<String, dynamic>.from(especificaciones['Estructura'] ?? {});
                                    // Compute excluded keys that belong to the Estructura section
                                    final Set<String> excludedEstructura = _excluidos
                                        .where((id) => id.startsWith('Estructura::'))
                                        .map((id) => id.split('::').length > 1 ? id.split('::').last : id)
                                        .toSet();

                                    // Build a filtered estructura map by removing excluded keys
                                    final Map<String, dynamic> estructuraFiltrada = Map<String, dynamic>.from(rawEstructura)
                                      ..removeWhere((k, v) => excludedEstructura.contains(k));

                                    widget.cotizacion.estructura = estructuraFiltrada;

                                    // Build adicionalesDeLinea but mark each kit with 'excluido' flag based on _excluidos
                                    final rawAdicionales = List<dynamic>.from(especificaciones['Adicionales de Línea'] ?? []);
                                    final List<dynamic> adicionalesConFlag = rawAdicionales.map((kit) {
                                      try {
                                        final nameRaw = (kit['name'] ?? '').toString();
                                        final name = nameRaw.trim();
                                        final kitId = 'kit::$name';
                                        final excluded = _excluidos.contains(kitId);
                                        final Map<String, dynamic> copy = Map<String, dynamic>.from(kit as Map);
                                        copy['excluido'] = excluded;
                                        return copy;
                                      } catch (_) {
                                        return kit;
                                      }
                                    }).toList();

                                    widget.cotizacion.adicionalesDeLinea = adicionalesConFlag;

                                    // Save excludedFeatures map in the cotizacion so Seccion4 PDF can filter by it
                                    widget.cotizacion.excludedFeatures = {
                                      'Estructura': excludedEstructura,
                                    };

                                    widget.cotizacion.adicionalesSeleccionados = _adicionalesSeleccionados.map((nombre) {
                                      return AdicionalSeleccionado(
                                        nombre: nombre,
                                        cantidad: _cantidadesAdicionales[nombre] ?? 1,
                                        precioUnitario: _preciosAdicionales[nombre] ?? 0.0,
                                        estado: _estadosAdicionales[nombre] ?? 'Desconocido',
                                      );
                                    }).toList();

                                    final double totalAdicionalesSeleccionados = _adicionalesSeleccionados.fold<double>(
                                      0.0,
                                      (sum, adicional) =>
                                          sum +
                                          ((_preciosAdicionales[adicional] ?? 0.0) *
                                              (_cantidadesAdicionales[adicional] ?? 1)),
                                    );
                                    final totalGeneral = _precioProductoConAdicionales + totalAdicionalesSeleccionados;

                                  final cotizacionActualizada = widget.cotizacion.copyWith(
                                      importe: totalGeneral,
                                      totalAdicionales: totalAdicionalesSeleccionados,
                                      precioProductoConAdicionales: _precioProductoConAdicionales,
                                    );

                                    final resultado = await Navigator.pushNamed(
                                      context,
                                      '/seccion3',
                                      arguments: {
                                        'cotizacion': cotizacionActualizada,
                                      },
                                    );

                                    if (resultado != null &&
                                        resultado is Map &&
                                        resultado['cotizacion'] != null) {
                                      setState(() {
                                        widget.cotizacion.estructura = resultado['cotizacion'].estructura;
                                        widget.cotizacion.adicionalesDeLinea = resultado['cotizacion'].adicionalesDeLinea;
                                        widget.cotizacion.adicionalesSeleccionados = resultado['cotizacion'].adicionalesSeleccionados;
                                        widget.cotizacion.importe = resultado['cotizacion'].importe;
                                        widget.cotizacion.totalAdicionales = resultado['cotizacion'].totalAdicionales;
                                        widget.cotizacion.precioProductoConAdicionales = resultado['cotizacion'].precioProductoConAdicionales;
                                        widget.cotizacion.formaPago = resultado['cotizacion'].formaPago;
                                        widget.cotizacion.metodoPago = resultado['cotizacion'].metodoPago;
                                        widget.cotizacion.moneda = resultado['cotizacion'].moneda;
                                        widget.cotizacion.entregaEn = resultado['cotizacion'].entregaEn;
                                        widget.cotizacion.costoEntrega = resultado['cotizacion'].costoEntrega;
                                        widget.cotizacion.garantia = resultado['cotizacion'].garantia;
                                        widget.cotizacion.cuentaSeleccionada = resultado['cotizacion'].cuentaSeleccionada;
                                        widget.cotizacion.otroMetodoPago = resultado['cotizacion'].otroMetodoPago;
                                        widget.cotizacion.fechaInicioEntrega = resultado['cotizacion'].fechaInicioEntrega;
                                        widget.cotizacion.fechaFinEntrega = resultado['cotizacion'].fechaFinEntrega;
                                        widget.cotizacion.semanasEntrega = resultado['cotizacion'].semanasEntrega;
                                        widget.cotizacion.numeroUnidades = resultado['cotizacion'].numeroUnidades;
                                        widget.cotizacion.anticipoSeleccionado = resultado['cotizacion'].anticipoSeleccionado;
                                        // excluded features removed from UI
                                      });
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                    elevation: 0,
                                  ),
                                  child: const Text('Siguiente'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMainSection({
    required String title,
    required Map<String, dynamic> content,
  }) {
    // Extrae solo el nombre del Dolly (antes de la primera coma)
    String dollyName = title.split(',').first.trim();
    // Extrae el resto de la configuración (después de la primera coma)
    String? configuracionExtra = title.contains(',')
        ? title.substring(title.indexOf(',') + 1).trim()
        : null;
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          // Chip centrado arriba del ExpansionTile
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [_chipEstadoProducto(_estadoProducto ?? '')],
            ),
          ),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: _expandedMainSections[title] ?? false,
              onExpansionChanged: (expanded) {
                setState(() {
                  _expandedMainSections[title] = expanded;
                });
              },
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      dollyName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[800],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatCurrency(_precioProductoConAdicionales),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (configuracionExtra != null && configuracionExtra.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 8),
                          child: Text(
                            configuracionExtra,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF1565C0),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      _buildUnifiedTable(content),
                      const Divider(
                        height: 32,
                        thickness: 1.2,
                        color: Color(0xFF1565C0),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 12, right: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text(
                              'Precio del Producto:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1565C0),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              formatCurrency(_precioProductoConAdicionales),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1565C0),
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
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedTable(Map<String, dynamic> content) {
    final List<TableRow> rows = [];

    content.forEach((sectionName, sectionContent) {
      rows.add(
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                sectionName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(),
          ],
        ),
      );

      if (sectionName == 'Adicionales de Línea' && sectionContent is List) {
        rows.addAll(_buildKitsAdicionalesRows(sectionContent));
      } else if (sectionContent is Map<String, dynamic>) {
        sectionContent.forEach((key, value) {
          final rowId = '$sectionName::$key';
          final excluded = _excluidos.contains(rowId);
          rows.add(
            TableRow(
              decoration: excluded
                  ? const BoxDecoration(color: Color(0xFFFFEBEE))
                  : null,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    key,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: excluded ? TextDecoration.lineThrough : TextDecoration.none,
                      color: excluded ? Colors.red : Colors.black87,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: value is List
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: value
                                    .map<Widget>((item) => Text('• $item', textAlign: TextAlign.justify, style: TextStyle(decoration: excluded ? TextDecoration.lineThrough : TextDecoration.none, color: excluded ? Colors.red : Colors.black87)))
                                    .toList(),
                              )
                            : Text(
                                value.toString(),
                                textAlign: TextAlign.justify,
                                style: TextStyle(decoration: excluded ? TextDecoration.lineThrough : TextDecoration.none, color: excluded ? Colors.red : Colors.black87),
                              ),
                      ),
                      IconButton(
                        icon: Icon(
                          excluded ? Icons.remove : Icons.add,
                          color: excluded ? Colors.red : Colors.green,
                        ),
                        onPressed: () {
                          setState(() {
                            // ignore: curly_braces_in_flow_control_structures
                            if (excluded) _excluidos.remove(rowId); else _excluidos.add(rowId);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
      }
    });
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.8),
        1: FlexColumnWidth(3.0),
      },
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      children: rows,
    );
  }

  List<TableRow> _buildKitsAdicionalesRows(List<dynamic> kits) {
    return kits
        .where((kit) => (kit['estado'] ?? '').toString().toLowerCase() != 'separador')
        .map<TableRow>((kit) {
      final name = kit['name'] ?? '';
      final adicionales = kit['adicionales'] ?? '';
      final kitId = 'kit::$name';
      final excluded = _excluidos.contains(kitId);

      return TableRow(
        decoration: excluded ? const BoxDecoration(color: Color(0xFFFFEBEE)) : null,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              name,
              style: TextStyle(fontWeight: FontWeight.w600, decoration: excluded ? TextDecoration.lineThrough : TextDecoration.none, color: excluded ? Colors.red : Colors.black87),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    adicionales,
                    textAlign: TextAlign.justify,
                    style: TextStyle(decoration: excluded ? TextDecoration.lineThrough : TextDecoration.none, color: excluded ? Colors.red : Colors.black87),
                  ),
                ),
                IconButton(
                  icon: Icon(excluded ? Icons.remove : Icons.add, color: excluded ? Colors.red : Colors.green),
                  onPressed: () {
                    setState(() {
                      // ignore: curly_braces_in_flow_control_structures
                      if (excluded) _excluidos.remove(kitId); else _excluidos.add(kitId);
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildAdicionalesCarrito() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 24),
      child: ExpansionTile(
        initiallyExpanded: true,
        onExpansionChanged: (expanded) {
          setState(() {
            _adicionalesTileExpanded = expanded;
          });
        },
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Equipamiento",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            // Solo mostrar el total cuando está colapsado
            if (!_adicionalesTileExpanded &&
                _adicionalesSeleccionados.isNotEmpty)
              Text(
                formatCurrency(
                  _adicionalesSeleccionados.fold<double>(
                    0.0,
                    (sum, adicional) =>
                        sum +
                        ((_preciosAdicionales[adicional] ?? 0.0) *
                            (_cantidadesAdicionales[adicional] ?? 1)),
                  ),
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1565C0),
                ),
              ),
          ],
        ),
        children: [
          Stack(
            children: [
              // Capa transparente para detectar taps fuera del Autocomplete
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    FocusScope.of(context).unfocus();
                  },
                  child: const SizedBox.expand(),
                ),
              ),
              // Tu contenido real encima
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // DROPDOWN
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return _gruposAdicionales.map((g) => g['text'] ?? '');
                        }
                        return _gruposAdicionales
                            .map((g) => g['text'] ?? '')
                            .where(
                              (option) => option.toLowerCase().contains(
                                textEditingValue.text.toLowerCase(),
                              ),
                            );
                      },
                      onSelected: (String selection) {
                        final grupo = _gruposAdicionales.firstWhere(
                          (g) => g['text'] == selection,
                        );
                        setState(() {
                          _grupoSeleccionadoId = grupo['value'];
                        });
                        _cargarItemsDelGrupo(grupo['value']!);
                        FocusScope.of(context).unfocus();
                        FocusScope.of(context).unfocus();
                      },
                      fieldViewBuilder:
                          (context, controller, focusNode, onEditingComplete) {
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText: "Selecciona una categoría",
                                labelStyle: const TextStyle(
                                  color: Color(0xFF1565C0),
                                ), // Azul
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF1565C0),
                                    width: 2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF1565C0),
                                    width: 2,
                                  ),
                                ),
                                suffixIcon: _grupoSeleccionadoId != null
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _grupoSeleccionadoId = null;
                                            _itemsDelGrupo.clear();
                                            controller.clear();
                                          });
                                        },
                                        splashRadius: 18,
                                      )
                                    : null,
                              ),
                            );
                          },
                      optionsViewBuilder: (context, onSelected, options) {
                        final itemCount = options.length;
                        final maxVisible = 4; // Máximo de opciones visibles
                        final height =
                            (itemCount < maxVisible ? itemCount : maxVisible) *
                            56.0;

                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            borderRadius: BorderRadius.circular(16),
                            elevation: 4,
                            child: SizedBox(
                              height: height,
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: itemCount,
                                itemBuilder: (context, index) {
                                  final option = options.elementAt(index);
                                  return ListTile(
                                    title: Text(option),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // LISTA DE ADICIONALES DEL GRUPO
                    if (_grupoSeleccionadoId != null)
                      _cargandoAdicionales
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF1565C0),
                                      ), // Azul
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      "Cargando Opcionales...",
                                      style: TextStyle(
                                        color: Color(0xFF1565C0),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _itemsDelGrupo.isNotEmpty
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Equipamiento disponibles:",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                // Search field
                                TextField(
                                  controller: _searchAdicionalesCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'Buscar equipamiento',
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      color: Color(0xFF1565C0),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF1565C0),
                                        width: 2,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF1565C0),
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                  ),
                                  onChanged: (q) {
                                    final query = q.toLowerCase();
                                    setState(() {
                                      _filteredItemsDelGrupo = _itemsDelGrupo.where((item) {
                                        final name = (item['name'] ?? '').toLowerCase();
                                        final estado = (item['estado'] ?? '').toLowerCase();
                                        final precio = (item['precio'] ?? '').toLowerCase();
                                        return name.contains(query) || estado.contains(query) || precio.contains(query);
                                      }).toList();
                                    });
                                  },
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 300,
                                  child: Scrollbar(
                                    controller: _scrollController,
                                    thumbVisibility: true,
                                    thickness: 6,
                                    radius: const Radius.circular(8),
                                    child: ListView.builder(
                                      controller: _scrollController,
                                      itemCount: _filteredItemsDelGrupo.length,
                                      itemBuilder: (context, index) {
                                        final item = _filteredItemsDelGrupo[index];
                                        final nombre = item['name'] ?? '';
                                        final precio = item['precio'] ?? '';
                                        final estado = item['estado'] ?? '';
                                        final isSelected =
                                            _adicionalesSeleccionados.contains(
                                              nombre,
                                            );
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 0,
                                          ),
                                          child: Card(
                                            color: const Color.fromARGB(
                                              235,
                                              236,
                                              236,
                                              236,
                                            ),
                                            elevation: 2,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              side: BorderSide(
                                                color: isSelected
                                                    ? Colors.green
                                                    : const Color.fromARGB(
                                                        255,
                                                        237,
                                                        237,
                                                        237,
                                                      ),
                                                width: isSelected ? 2 : 1,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                              child: SizedBox(
                                                height: 116,
                                                child: Stack(
                                                  children: [
                                                    // Top-left chip
                                                    Positioned(
                                                      left: 6,
                                                      top: 6,
                                                      child: _chipEstado(estado),
                                                    ),
                                                    // Top-right circular add/check button
                                                    Positioned(
                                                      right: 6,
                                                      top: 6,
                                                      child: Container(
                                                        width: 36,
                                                        height: 36,
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          border: Border.all(color: Colors.grey.shade300),
                                                          color: Colors.white,
                                                        ),
                                                        child: IconButton(
                                                          padding: EdgeInsets.zero,
                                                          iconSize: 20,
                                                          icon: Icon(
                                                            isSelected ? Icons.check : Icons.add,
                                                            color: isSelected ? Colors.green : Colors.grey,
                                                          ),
                                                          onPressed: () {
                                                            setState(() {
                                                              if (isSelected) {
                                                                _adicionalesSeleccionados.remove(nombre);
                                                                _cantidadesAdicionales.remove(nombre);
                                                                _preciosAdicionales.remove(nombre);
                                                                _estadosAdicionales.remove(nombre);
                                                              } else {
                                                                _adicionalesSeleccionados.add(nombre);
                                                                _cantidadesAdicionales[nombre] = 1;
                                                                _preciosAdicionales[nombre] =
                                                                    double.tryParse(precio.replaceAll('4', '').replaceAll(',', '')) ?? 0.0;
                                                                _estadosAdicionales[nombre] = estado;
                                                              }
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                    // Main content: name and price
                                                    Positioned(
                                                      left: 12,
                                                      right: 12,
                                                      top: 62,
                                                      child: Row(
                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                        children: [
                                                          Expanded(
                                                            child: GestureDetector(
                                                              onTap: () {
                                                                showDialog(
                                                                  context: context,
                                                                  builder: (_) => AlertDialog(
                                                                    backgroundColor: Colors.white,
                                                                    shape: RoundedRectangleBorder(
                                                                      borderRadius: BorderRadius.circular(20),
                                                                      side: const BorderSide(color: Color(0xFF1565C0), width: 1),
                                                                    ),
                                                                    titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                                                                    contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                                                                    actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                                                    title: Text(
                                                                      nombre,
                                                                      style: const TextStyle(
                                                                        color: Color(0xFF1565C0),
                                                                        fontSize: 20,
                                                                        fontWeight: FontWeight.bold,
                                                                        height: 1.12,
                                                                      ),
                                                                    ),
                                                                    content: SingleChildScrollView(
                                                                      child: Column(
                                                                        mainAxisSize: MainAxisSize.min,
                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                        children: [
                                                                            const SizedBox(height: 8),
                                                                            Text(
                                                                              'Precio: ${formatCurrency(double.tryParse(precio.replaceAll('\u00024', '').replaceAll(',', '')) ?? 0.0)}',
                                                                              style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w600),
                                                                            ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    actions: [
                                                                      TextButton(
                                                                        onPressed: () => Navigator.pop(context),
                                                                        style: TextButton.styleFrom(
                                                                          foregroundColor: const Color(0xFF1565C0),
                                                                        ),
                                                                        child: const Text('Cerrar'),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                );
                                                              },
                                                              child: Tooltip(
                                                                message: nombre,
                                                                child: Text(
                                                                  nombre,
                                                                  style: const TextStyle(
                                                                    fontSize: 14,
                                                                    color: Colors.black87,
                                                                    fontWeight: FontWeight.w600,
                                                                  ),
                                                                  maxLines: 3,
                                                                  overflow: TextOverflow.ellipsis,
                                                                  textAlign: TextAlign.left,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 12),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                            decoration: BoxDecoration(
                                                              color: const Color(0xFFF7F4FB),
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            child: Text(
                                                              formatCurrency(
                                                                double.tryParse(precio.replaceAll('4', '').replaceAll(',', '')) ?? 0.0,
                                                              ),
                                                              style: const TextStyle(
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 13,
                                                                color: Colors.blueGrey,
                                                              ),
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
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    // Divider y sección de adicionales seleccionados
                    if (_adicionalesSeleccionados.isNotEmpty) ...[
                      const Divider(
                        height: 32,
                        thickness: 1.2,
                        color: Color(0xFF1565C0),
                      ),
                      const Text(
                        "Equipamiento Seleccionados:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 220,
                        child: Scrollbar(
                          thumbVisibility: true,
                          thickness: 6,
                          radius: const Radius.circular(8),
                          child: ListView.builder(
                            itemCount: _adicionalesSeleccionados.length,
                            itemBuilder: (context, index) {
                              final adicional =
                                  _adicionalesSeleccionados[index];
                              final precioUnitario =
                                  _preciosAdicionales[adicional] ?? 0.0;
                              final cantidad =
                                  _cantidadesAdicionales[adicional] ?? 1;
                              final total = precioUnitario * cantidad;

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 0,
                                ),
                                child: Card(
                                  color: const Color.fromARGB(
                                    235,
                                    236,
                                    236,
                                    236,
                                  ),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 14,
                                    ),
                                    child: SizedBox(
                                      height: 116,
                                      child: Stack(
                                        children: [
                                          // Chip top-left
                                          Positioned(
                                            left: 6,
                                            top: 6,
                                            child: _chipEstado(
                                              _estadosAdicionales[adicional] ?? 'Sin Estado',
                                            ),
                                          ),
                                          // Top-right delete button (red)
                                          Positioned(
                                            right: 6,
                                            top: 6,
                                            child: Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white,
                                                border: Border.all(color: Colors.grey.shade300),
                                              ),
                                              child: IconButton(
                                                padding: EdgeInsets.zero,
                                                iconSize: 20,
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  color: Color.fromARGB(211, 186, 4, 4),
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _adicionalesSeleccionados.remove(adicional);
                                                    _cantidadesAdicionales.remove(adicional);
                                                    _preciosAdicionales.remove(adicional);
                                                    _estadosAdicionales.remove(adicional);
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                          // Main content: name and total price
                                          Positioned(
                                            left: 12,
                                            right: 12,
                                            top: 62,
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (_) => AlertDialog(
                                                          backgroundColor: Colors.white,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(20),
                                                            side: const BorderSide(color: Color(0xFF1565C0), width: 1),
                                                          ),
                                                          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                                                          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                                                          actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                                          title: Text(
                                                            adicional,
                                                            style: const TextStyle(
                                                              color: Color(0xFF1565C0),
                                                              fontSize: 20,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                          content: Column(
                                                            mainAxisSize: MainAxisSize.min,
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              const SizedBox(height: 8),
                                                              Text('Precio: ${formatCurrency(precioUnitario)}', style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w600)),
                                                            ],
                                                          ),
                                                            actions: [
                                                            TextButton(
                                                              onPressed: () => Navigator.pop(context),
                                                              style: TextButton.styleFrom(
                                                                foregroundColor: const Color(0xFF1565C0),
                                                              ),
                                                              child: const Text('Cerrar'),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                    child: Tooltip(
                                                      message: adicional,
                                                      child: Text(
                                                        adicional,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.black87,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                        maxLines: 3,
                                                        overflow: TextOverflow.ellipsis,
                                                        textAlign: TextAlign.left,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF7F4FB),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    formatCurrency(total),
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                      color: Colors.blueGrey,
                                                    ),
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
                            },
                          ),
                        ),
                      ),
                      // Total adicionales
                      const Divider(
                        height: 32,
                        thickness: 1.2,
                        color: Color(0xFF1565C0),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 12, right: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text(
                              'Total de Equipamientos:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 12),

                            Text(
                              formatCurrency(
                                _adicionalesSeleccionados.fold<double>(
                                  0.0,
                                  (sum, adicional) =>
                                      sum +
                                      ((_preciosAdicionales[adicional] ?? 0.0) *
                                          (_cantidadesAdicionales[adicional] ??
                                              1)),
                                ),
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1565C0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoader() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 255, 255),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
            ),
            const SizedBox(height: 16),
            const Text(
              "Cargando Estructura...",
              style: TextStyle(
                color: Color(0xFF1565C0),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalGeneralCard() {
    final double totalAdicionalesSeleccionados = _adicionalesSeleccionados.fold<double>(
      0.0,
      (sum, adicional) =>
          sum +
          ((_preciosAdicionales[adicional] ?? 0.0) *
              (_cantidadesAdicionales[adicional] ?? 1)),
    );
    final totalGeneral = _precioProductoConAdicionales + totalAdicionalesSeleccionados;
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 24),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
        title: const Text(
          "Importe",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        trailing: Text(
          formatCurrency(totalGeneral),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF1565C0),
          ),
        ),
      ),
    );
  }

  // Widget to display the estado as a Chip
  Widget _chipEstado(String estado) {
    Color chipColor;
    Color textColor = Colors.white;
    String label;

    switch (estado.toLowerCase()) {
      case 'costeo aprobado':
      case 'aprobado':
        label = 'Aprobado';
        chipColor = Colors.green;
        break;
      case 'pendiente revisión':
      case 'p/revisión':
      case 'preparado p/revisión':
        label = 'P/Revisión';
        chipColor = const Color.fromARGB(255, 25, 103, 167);
        textColor = Colors.white;
        break;
      case 'sin aprobar':
        label = 'Sin aprobar';
        chipColor = Colors.orange;
        break;
      default:
        label = estado;
        chipColor = Colors.grey;
        textColor = Colors.white;
    }

    return Chip(
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Kit',
            style: TextStyle(fontSize: 11, color: Colors.white),
          ),

          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipEstadoProducto(String estado) {
    Color chipColor;
    Color textColor = Colors.white;
    String label;

    switch (estado.toLowerCase()) {
      case 'costeo aprobado':
      case 'aprobado':
        label = 'Aprobado';
        chipColor = const Color(0xFF388E3C); // Verde
        break;
      case 'terminado':
        label = 'Terminado';
        chipColor = const Color.fromARGB(255, 215, 127, 50); // Morado
        break;
      case 'pendiente revisión':
      case 'p/revisión':
      case 'preparado p/revisión':
        label = 'P/Revisión';
        chipColor = Color.fromARGB(255, 255, 198, 29); // Naranja
        textColor = Colors.black;
        break;
      case 'sin aprobar':
        label = 'Sin Aprobar';
        chipColor = const Color(0xFFBDBDBD); // Gris
        textColor = Colors.black;
        break;
      default:
        label = estado;
        chipColor = Colors.grey;
        textColor = Colors.white;
    }

    return Container(
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Precio: ',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ...existing code...
}

// Progress bar widget for steps
class StepHeaderBar extends StatelessWidget {
  final int pasoActual;
  final int totalPasos;

  const StepHeaderBar({
    required this.pasoActual,
    required this.totalPasos,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Línea amarilla sobre fondo negro
        Stack(
          children: [
            Container(width: double.infinity, height: 6, color: Colors.black),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pasoActual / totalPasos,
              child: Container(height: 6, color: const Color(0xFFD9CF6A)),
            ),
          ],
        ),
        Container(
          width: double.infinity,
          color: Colors.blue.shade800,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: Text(
              'Paso $pasoActual de $totalPasos',
              style: const TextStyle(
                color: Color.fromARGB(255, 255, 255, 255),
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String formatCurrency(num value) {
  final formatter = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
  return formatter.format(value);
}
