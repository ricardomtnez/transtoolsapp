import 'package:flutter/material.dart';
import 'package:transtools/api/quote_controller.dart';
import 'package:transtools/models/adicional_seleccionado.dart';
import 'package:transtools/models/cotizacion.dart';
import 'package:intl/intl.dart';

class Seccion2 extends StatefulWidget {
  final String modeloNombre; // 👈 Aquí defines la propiedad
  final String modeloValue;
  final String configuracionProducto;
  final Cotizacion cotizacion;

  const Seccion2({
    super.key,
    required this.modeloNombre, // 👈 Aquí lo asignas
    required this.modeloValue,
    required this.configuracionProducto,
    required this.cotizacion,
  });
  @override
  State<Seccion2> createState() => _Seccion2State();
}

class _Seccion2State extends State<Seccion2> {
  final ScrollController _scrollController = ScrollController();
  String titulo =
      'Semirremolque tipo Plataforma'; // O puedes cambiarlo por el que venga desde la API si lo deseas
  Map<String, dynamic> especificaciones = {}; // Aquí se cargan los datos reales

  String? _estadoProducto;

  final Map<String, bool> _expandedMainSections = {
    'Especificaciones Técnicas': true,
    'Adicionales': true,
  };
  final Map<String, Set<String>> _excludedFeatures = {};

  // VARIABLES
  final List<Map<String, String>> _gruposAdicionales =
      []; // [{value: id, text: titulo}]
  String? _grupoSeleccionadoId;
  final List<Map<String, String>> _itemsDelGrupo = [];
  final List<String> _adicionalesSeleccionados = [];
  bool _cargandoAdicionales = false;

  final Map<String, int> _cantidadesAdicionales = {};
  final Map<String, double> _preciosAdicionales = {};
  final Map<String, String> _estadosAdicionales = {}; // <-- NUEVO

  bool _adicionalesTileExpanded = true; // <-- NUEVO

  // Variables de control y datos
  double _precioProductoBase = 0;
  double _precioProductoConAdicionales = 0;
  double _rentabilidad = 0.0;
  bool _precioCargado = false;
  @override
  void initState() {
    super.initState();
    _cargarUsuario();
    _cargarCategoriasAdicionales();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _cargarUsuario() async {
    const boardId = 9364424510; // Cambia esto por el ID del board correcto

    // Función auxiliar para extraer la clave hasta el 4º guion
    String extraerClaveHastaCuartoGuion(String texto) {
      final partes = texto.split('-');
      if (partes.length >= 4) {
        return partes.sublist(0, 4).join('-');
      } else {
        return texto; // Si no tiene 4 guiones, regresa el texto completo
      }
    }

    try {
      final grupos = await QuoteController.obtenerGruposEstructura(boardId);

      Map<String, dynamic>? grupoCoincidente;
      try {
        grupoCoincidente = grupos.firstWhere((grupo) {
          final grupoClave = extraerClaveHastaCuartoGuion(
            grupo['text']!.toLowerCase(),
          );
          final modeloClave = extraerClaveHastaCuartoGuion(
            widget.modeloNombre.toLowerCase(),
          );
          return grupoClave == modeloClave;
        });
      } catch (e) {
        grupoCoincidente = null; // No se encontró grupo coincidente
      }

      if (grupoCoincidente != null) {
        final String grupoId = grupoCoincidente['value']!;
        // Llama la función para cargar ficha técnica con grupoId y otroBoardId
        _cargarFichaTecnica(grupoId, boardId);
      } else {
        if (!mounted) return;
        // Mostrar alerta de no encontrado
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Grupo no encontrado'),
            content: Text(
              'No se encontró la estructura del modelo: ${widget.modeloNombre}',
            ),
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
      // Mostrar alerta de error
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

      final adicionales = await QuoteController.obtenerKitsAdicionales(
        idItemInt,
      );

      setState(() {
        especificaciones['Adicionales de Línea'] = adicionales;
      });
      // Después de guardar adicionales, ahora sí carga el precio
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
      final precioData = await QuoteController.obtenerPrecioProducto(
        idProducto,
      );
      final subtotal = precioData['subtotal'] ?? 0.0;
      final rentabilidad = precioData['rentabilidad'] ?? 0.0;
      final estado = precioData['estado'] ?? ''; // <-- agrega esto

      setState(() {
        _precioProductoBase = subtotal;
        _rentabilidad = rentabilidad;
        _precioCargado = true;
        _estadoProducto = estado; // <-- guarda el estado aquí
        _actualizarPrecioConAdicionales();
      });
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

  //Cargar categorias de adicionales seleccionados
  Future<void> _cargarCategoriasAdicionales() async {
    try {
      const boardId = 8890947131;
      final gruposApi = await QuoteController.obtenerCategoriasAdicionales(
        boardId,
      );
      // print(gruposApi);
      setState(() {
        _gruposAdicionales.clear();
        _gruposAdicionales.addAll(
          gruposApi.map<Map<String, String>>((g) {
            return {
              'value': g['value']?.toString() ?? '',
              'text': g['text']?.toString() ?? '',
            };
          }),
        );
      });
      //print('Grupos adicionales cargados: $_gruposAdicionales');
    } catch (e) {
      // Manejar error
    }
  }

  //Cargar adicionales de la categoria seleccionada.
  Future<void> _cargarItemsDelGrupo(String grupoId) async {
    setState(() {
      _cargandoAdicionales = true;
    });
    try {
      final itemsApi = await QuoteController.obtenerAdicionalesPorCategoria(
        grupoId,
      );
      setState(() {
        _itemsDelGrupo.clear();
        _itemsDelGrupo.addAll(itemsApi);
      });
    } catch (e) {
      // Maneja error
    } finally {
      setState(() {
        _cargandoAdicionales = false;
      });
    }
  }

  //
  void _actualizarPrecioConAdicionales() {
    double totalAdicionales = 0;

    final adicionales = especificaciones['Adicionales de Línea'] ?? [];

    final excluidos = (_excludedFeatures['Adicionales de Línea'] ?? {})
        .toList();

    try {
      for (var adicional in adicionales) {
        final cantidad = (adicional['cantidad'] is int)
            ? adicional['cantidad'] as int
            : int.tryParse(adicional['cantidad'].toString()) ?? 0;

        final precio = (adicional['precio'] is double)
            ? adicional['precio'] as double
            : double.tryParse(adicional['precio'].toString()) ?? 0.0;

        final nombre = adicional['name'] ?? '';

        if (!excluidos.contains(nombre)) {
          totalAdicionales += cantidad * precio;
        } else {
          totalAdicionales += cantidad * precio * 0.2;
        }
      }
    } catch (e) {
      //print('Error al calcular adicionales: $e');
    }

    final subtotalConAdicionales = _precioProductoBase + totalAdicionales;
    final totalFinal = (subtotalConAdicionales / (1 - _rentabilidad)) / 1.16;

    setState(() {
      _precioProductoConAdicionales = totalFinal;
    });
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
          // Quita el leading personalizado y deja que Flutter ponga la flechita
          title: const Text(
            'Estructura del Producto',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          centerTitle: true,
        ),
        // Quita el drawer:
        // drawer: Drawer(...),  <-- Elimina esta línea y su contenido
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
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
                                    widget.cotizacion.estructura =
                                        especificaciones['Estructura'] ?? {};
                                    widget.cotizacion.adicionalesDeLinea =
                                        especificaciones['Adicionales de Línea'] ??
                                        [];
                                    widget.cotizacion.adicionalesSeleccionados =
                                        _adicionalesSeleccionados.map((nombre) {
                                          return AdicionalSeleccionado(
                                            nombre: nombre,
                                            cantidad:
                                                _cantidadesAdicionales[nombre] ??
                                                1,
                                            precioUnitario:
                                                _preciosAdicionales[nombre] ??
                                                0.0,
                                            estado:
                                                _estadosAdicionales[nombre] ??
                                                'Desconocido',
                                          );
                                        }).toList();

                                    final double totalAdicionalesSeleccionados =
                                        _adicionalesSeleccionados.fold<double>(
                                          0.0,
                                          (sum, adicional) =>
                                              sum +
                                              ((_preciosAdicionales[adicional] ??
                                                      0.0) *
                                                  (_cantidadesAdicionales[adicional] ??
                                                      1)),
                                        );
                                    final totalGeneral =
                                        _precioProductoConAdicionales +
                                        totalAdicionalesSeleccionados;

                                    final cotizacionActualizada = widget
                                        .cotizacion
                                        .copyWith(
                                          importe: totalGeneral,
                                          totalAdicionales:
                                              totalAdicionalesSeleccionados,
                                          precioProductoConAdicionales:
                                              _precioProductoConAdicionales,
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
                                        widget.cotizacion.estructura =
                                            resultado['cotizacion'].estructura;
                                        widget.cotizacion.adicionalesDeLinea =
                                            resultado['cotizacion']
                                                .adicionalesDeLinea;
                                        widget
                                                .cotizacion
                                                .adicionalesSeleccionados =
                                            resultado['cotizacion']
                                                .adicionalesSeleccionados;
                                        widget.cotizacion.importe =
                                            resultado['cotizacion'].importe;
                                        widget.cotizacion.totalAdicionales =
                                            resultado['cotizacion']
                                                .totalAdicionales;
                                        widget
                                                .cotizacion
                                                .precioProductoConAdicionales =
                                            resultado['cotizacion']
                                                .precioProductoConAdicionales;
                                        widget.cotizacion.formaPago =
                                            resultado['cotizacion'].formaPago;
                                        widget.cotizacion.metodoPago =
                                            resultado['cotizacion'].metodoPago;
                                        widget.cotizacion.moneda =
                                            resultado['cotizacion'].moneda;
                                        widget.cotizacion.entregaEn =
                                            resultado['cotizacion'].entregaEn;
                                        widget.cotizacion.garantia =
                                            resultado['cotizacion'].garantia;
                                        widget.cotizacion.cuentaSeleccionada =
                                            resultado['cotizacion']
                                                .cuentaSeleccionada;
                                        widget.cotizacion.otroMetodoPago =
                                            resultado['cotizacion']
                                                .otroMetodoPago;
                                        widget.cotizacion.fechaInicioEntrega =
                                            resultado['cotizacion']
                                                .fechaInicioEntrega;
                                        widget.cotizacion.fechaFinEntrega =
                                            resultado['cotizacion']
                                                .fechaFinEntrega;
                                        widget.cotizacion.semanasEntrega =
                                            resultado['cotizacion']
                                                .semanasEntrega;
                                        widget.cotizacion.numeroUnidades =
                                            resultado['cotizacion']
                                                .numeroUnidades;
                                      });
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
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
                  Text(
                    dollyName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[800],
                    ),
                    overflow: TextOverflow.ellipsis,
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
                      // Muestra la configuración
                      if (configuracionExtra != null &&
                          configuracionExtra.isNotEmpty)
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
                      // Aquí va la tabla
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
                                color: Color.fromARGB(221, 255, 255, 255),
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
            const SizedBox(),
          ],
        ),
      );

      if (sectionName == 'Adicionales de Línea' && sectionContent is List) {
        rows.addAll(_buildKitsAdicionalesRows(sectionContent));
      } else if (sectionContent is Map<String, dynamic>) {
        sectionContent.forEach((key, value) {
          final isExcluded =
              _excludedFeatures[sectionName]?.contains(key) ?? false;

          rows.add(
            TableRow(
              decoration: BoxDecoration(
                color: isExcluded ? Colors.red.shade50 : null,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    key,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isExcluded ? Colors.red : null,
                      decoration: isExcluded
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: value is List
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: value
                              .map<Widget>(
                                (item) => Text(
                                  '• $item',
                                  textAlign: TextAlign.justify,
                                  style: TextStyle(
                                    color: isExcluded ? Colors.red : null,
                                    decoration: isExcluded
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              )
                              .toList(),
                        )
                      : Text(
                          value.toString(),
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            color: isExcluded ? Colors.red : null,
                            decoration: isExcluded
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                ),
                Center(
                  child: IconButton(
                    icon: Icon(
                      isExcluded ? Icons.add : Icons.remove,
                      color: isExcluded ? Colors.green : Colors.red,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isExcluded) {
                          _excludedFeatures[sectionName]?.remove(key);
                        } else {
                          _excludedFeatures
                              .putIfAbsent(sectionName, () => <String>{})
                              .add(key);
                        }
                      });
                    },
                    tooltip: isExcluded ? 'Incluir' : 'Excluir',
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
        1: FlexColumnWidth(2.5),
        2: FlexColumnWidth(0.5),
      },
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      children: rows,
    );
  }

  List<TableRow> _buildKitsAdicionalesRows(List<dynamic> kits) {
    return kits.map<TableRow>((kit) {
      final name = kit['name'] ?? '';
      final adicionales = kit['adicionales'] ?? '';
      // El estado visual depende de _excludedFeatures, pero el estado funcional depende de 'excluido'
      final isExcluded = kit['excluido'] == false;

      return TableRow(
        decoration: BoxDecoration(
          color: isExcluded ? Colors.red.shade50 : null,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isExcluded ? Colors.red : null,
                decoration: isExcluded ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              adicionales,
              textAlign: TextAlign.justify,
              style: TextStyle(
                color: isExcluded ? Colors.red : null,
                decoration: isExcluded ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Center(
            child: IconButton(
              icon: Icon(
                isExcluded ? Icons.add : Icons.remove,
                color: isExcluded ? Colors.green : Colors.red,
              ),
              onPressed: () {
                setState(() {
                  kit['excluido'] = !(kit['excluido'] == true);
                  if (kit['excluido'] == true) {
                    _excludedFeatures['Adicionales de Línea']?.remove(name);
                  } else {
                    _excludedFeatures
                        .putIfAbsent('Adicionales de Línea', () => <String>{})
                        .add(name);
                  }
                  _actualizarPrecioConAdicionales();
                });
              },
              tooltip: isExcluded ? 'Incluir' : 'Excluir',
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
              "Adicionales",
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
                                      "Cargando Adicionales...",
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
                                  "Adicionales disponibles:",
                                  style: TextStyle(fontWeight: FontWeight.bold),
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
                                      itemCount: _itemsDelGrupo.length,
                                      itemBuilder: (context, index) {
                                        final item = _itemsDelGrupo[index];
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 18,
                                                    horizontal: 22,
                                                  ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // IZQUIERDA: Chip y texto
                                                  Expanded(
                                                    flex: 2,
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        _chipEstado(estado),
                                                        const SizedBox(
                                                          height: 12,
                                                        ),
                                                        Text(
                                                          nombre,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 13,
                                                                color: Colors
                                                                    .black87,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                          maxLines: 3,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // DERECHA: Botón + y precio
                                                  Expanded(
                                                    flex: 1,
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .end,
                                                      children: [
                                                        IconButton(
                                                          iconSize: 25,
                                                          icon: Icon(
                                                            isSelected
                                                                ? Icons
                                                                      .check_circle
                                                                : Icons
                                                                      .add_circle_outline,
                                                            color: isSelected
                                                                ? Colors.green
                                                                : Colors.grey,
                                                          ),
                                                          onPressed: () {
                                                            setState(() {
                                                              if (isSelected) {
                                                                _adicionalesSeleccionados
                                                                    .remove(
                                                                      nombre,
                                                                    );
                                                                _cantidadesAdicionales
                                                                    .remove(
                                                                      nombre,
                                                                    );
                                                                _preciosAdicionales
                                                                    .remove(
                                                                      nombre,
                                                                    );
                                                                _estadosAdicionales
                                                                    .remove(
                                                                      nombre,
                                                                    ); // <-- NUEVO
                                                              } else {
                                                                _adicionalesSeleccionados
                                                                    .add(
                                                                      nombre,
                                                                    );
                                                                _cantidadesAdicionales[nombre] =
                                                                    1;
                                                                _preciosAdicionales[nombre] =
                                                                    double.tryParse(
                                                                      precio
                                                                          .replaceAll(
                                                                            '\$',
                                                                            '',
                                                                          )
                                                                          .replaceAll(
                                                                            ',',
                                                                            '',
                                                                          ),
                                                                    ) ??
                                                                    0.0;
                                                                _estadosAdicionales[nombre] =
                                                                    estado; // <-- NUEVO: guarda el estado
                                                              }
                                                            });
                                                          },
                                                        ),
                                                        const SizedBox(
                                                          height: 24,
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 4,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: const Color(
                                                              0xFFF7F4FB,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  6,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            formatCurrency(
                                                              double.tryParse(
                                                                    precio
                                                                        .replaceAll(
                                                                          '\$',
                                                                          '',
                                                                        )
                                                                        .replaceAll(
                                                                          ',',
                                                                          '',
                                                                        ),
                                                                  ) ??
                                                                  0.0,
                                                            ),
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 13,
                                                                  color: Colors
                                                                      .blueGrey,
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
                        "Adicionales Seleccionados:",
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
                                      vertical: 14,
                                      horizontal: 18,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Fila superior: Chip y botón de quitar
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            _chipEstado(
                                              _estadosAdicionales[adicional] ??
                                                  'Sin Estado',
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Color.fromARGB(
                                                  211,
                                                  186,
                                                  4,
                                                  4,
                                                ),
                                                size: 25,
                                              ),
                                              tooltip: 'Quitar',
                                              onPressed: () {
                                                setState(() {
                                                  _adicionalesSeleccionados
                                                      .remove(adicional);
                                                  _cantidadesAdicionales.remove(
                                                    adicional,
                                                  );
                                                  _preciosAdicionales.remove(
                                                    adicional,
                                                  );
                                                  _estadosAdicionales.remove(
                                                    adicional,
                                                  );
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        // Descripción
                                        Text(
                                          adicional,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        // Precio unitario pequeño
                                        Text(
                                          '${formatCurrency(precioUnitario)} c/u',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Colors.blueGrey,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Selector de cantidad y total
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.remove_circle_outline,
                                                    color: Color(0xFF1565C0),
                                                  ),
                                                  iconSize: 25,
                                                  onPressed: () {
                                                    if (cantidad > 1) {
                                                      setState(() {
                                                        _cantidadesAdicionales[adicional] =
                                                            cantidad - 1;
                                                      });
                                                    }
                                                  },
                                                ),
                                                Text(
                                                  '$cantidad',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.add_circle_outline,
                                                    color: Color(0xFF1565C0),
                                                  ),
                                                  iconSize: 25,
                                                  onPressed: () {
                                                    setState(() {
                                                      _cantidadesAdicionales[adicional] =
                                                          cantidad + 1;
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                            // TOTAL con estilo de etiqueta
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF7F4FB),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                formatCurrency(total),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: Colors.blueGrey,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                            ),
                                          ],
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
                              'Total adicionales:',
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

  Widget _buildTotalGeneralCard() {
    final double totalAdicionalesSeleccionados = _adicionalesSeleccionados
        .fold<double>(
          0.0,
          (sum, adicional) =>
              sum +
              ((_preciosAdicionales[adicional] ?? 0.0) *
                  (_cantidadesAdicionales[adicional] ?? 1)),
        );
    final totalGeneral =
        _precioProductoConAdicionales + totalAdicionalesSeleccionados;
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
