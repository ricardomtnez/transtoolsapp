import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transtools/api/quote_controller.dart';
import 'package:transtools/models/usuario.dart';

class Seccion2 extends StatefulWidget {
  final String modeloNombre; // 👈 Aquí defines la propiedad
  final String modeloValue;
  final String configuracionProducto;

  const Seccion2({
    super.key,
    required this.modeloNombre, // 👈 Aquí lo asignas
    required this.modeloValue,
    required this.configuracionProducto,
  });
  @override
  State<Seccion2> createState() => _Seccion2State();
}

class _Seccion2State extends State<Seccion2> {
  final ScrollController _scrollController = ScrollController();
  Usuario? _usuario;
  String titulo =
      'Semirremolque tipo Plataforma'; // O puedes cambiarlo por el que venga desde la API si lo deseas
  Map<String, dynamic> especificaciones = {}; // Aquí se cargan los datos reales

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

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
    _cargarDatosModeloSeleccionado();
    _cargarCategoriasAdicionales();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _cargarUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('usuario');
    if (jsonString != null) {
      setState(() {
        _usuario = Usuario.fromJson(
          jsonString,
        ); // Ya devuelve un objeto Usuario
      });
    }
  }

  void _cargarDatosModeloSeleccionado() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: const Text(
          'Estructura del Producto',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
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
              Column(
                children: [
                  const SizedBox(height: 60),
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  // Espacio entre el avatar y el nombre
                  const SizedBox(height: 10),
                  // Nombre del usuario
                  Text(
                    _usuario?.fullname ?? 'Nombre no disponible',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.dashboard),
                    title: const Text('Menu Principal'),
                    onTap: () {
                      Navigator.pushNamed(context, '/dashboard');
                    },
                  ),
                ],
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
      backgroundColor: Colors.blue[800],
      body: especificaciones.isEmpty
          ? _buildLoader()
          : Column(
              children: [
                StepHeaderBar(pasoActual: 2, totalPasos: 4),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildMainSection(
                          title: widget.configuracionProducto,
                          content: especificaciones,
                        ),
                        _buildAdicionalesCarrito(),
                        
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
                                onPressed: () {
                                  Navigator.pushNamed(context, '/seccion3');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Colors.white, // <-- Igual que "Atrás"
                                  foregroundColor:
                                      Colors.black, // <-- Igual que "Atrás"
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
    );
  }

  Widget _buildMainSection({
    required String title,
    required Map<String, dynamic> content,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 24),
      child: ExpansionTile(
        initiallyExpanded: _expandedMainSections[title] ?? false,
        onExpansionChanged: (expanded) {
          setState(() {
            _expandedMainSections[title] = expanded;
          });
        },
        title: SizedBox(
          width: double.infinity, // Ocupa todo el ancho disponible
          child: Text(
            title,
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.blue[800],
              height: 1.4, // Más espacio entre líneas
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildUnifiedTable(content),
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
                              .map<Widget>((item) => Text(
                                    '• $item',
                                    textAlign: TextAlign.justify, // <-- Justifica listas también
                                    style: TextStyle(
                                      color: isExcluded ? Colors.red : null,
                                      decoration: isExcluded ? TextDecoration.lineThrough : null,
                                    ),
                                  ))
                              .toList(),
                        )
                      : Text(
                          value.toString(),
                          textAlign: TextAlign.justify, // <-- Justifica el texto de valor
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

      // Verificamos si está excluido en _excludedFeatures
      final isExcluded =
          _excludedFeatures['Adicionales de Línea']?.contains(name) ?? false;

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
              textAlign: TextAlign.justify, // <-- Justifica el texto
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
                  if (isExcluded) {
                    _excludedFeatures['Adicionales de Línea']?.remove(name);
                  } else {
                    _excludedFeatures
                        .putIfAbsent('Adicionales de Línea', () => <String>{})
                        .add(name);
                  }
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
        title: Text(
          "Adicionales",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        children: [
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
                        .where((option) => option
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (String selection) {
                    final grupo = _gruposAdicionales.firstWhere((g) => g['text'] == selection);
                    setState(() {
                      _grupoSeleccionadoId = grupo['value'];
                    });
                    _cargarItemsDelGrupo(grupo['value']!);
                    FocusScope.of(context).unfocus(); 
                  },
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: "Selecciona una categoría",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                      ),
                      suffixIcon: _grupoSeleccionadoId != null
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
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
                    final height = (itemCount < maxVisible ? itemCount : maxVisible) * 56.0; 

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
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)), // Azul
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
                                        final displayText = '$nombre - \$$precio - $estado';
                                        final isSelected = _adicionalesSeleccionados.contains(nombre);

                                        return ListTile(
                                          title: Text(displayText),
                                          trailing: Icon(
                                            isSelected ? Icons.check_circle : Icons.add_circle_outline,
                                            color: isSelected ? Colors.green : Colors.grey,
                                          ),
                                          onTap: () {
                                            setState(() {
                                              if (isSelected) {
                                                _adicionalesSeleccionados.remove(nombre);
                                                _cantidadesAdicionales.remove(nombre);
                                              } else {
                                                _adicionalesSeleccionados.add(nombre);
                                                _cantidadesAdicionales[nombre] = 1;
                                              }
                                            });
                                          },
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
                      color: Colors.blue,
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
                          final adicional = _adicionalesSeleccionados[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    adicional,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.blue),
                                  onPressed: () {
                                    setState(() {
                                      if ((_cantidadesAdicionales[adicional] ?? 1) > 1) {
                                        _cantidadesAdicionales[adicional] =
                                            (_cantidadesAdicionales[adicional] ?? 1) - 1;
                                      }
                                    });
                                  },
                                ),
                                Text(
                                  '${_cantidadesAdicionales[adicional] ?? 1}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                                  onPressed: () {
                                    setState(() {
                                      _cantidadesAdicionales[adicional] =
                                          (_cantidadesAdicionales[adicional] ?? 1) + 1;
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  tooltip: 'Quitar',
                                  onPressed: () {
                                    setState(() {
                                      _adicionalesSeleccionados.remove(adicional);
                                      _cantidadesAdicionales.remove(adicional);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
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
