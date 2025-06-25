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
  Usuario? _usuario;
  String titulo =
      'Semirremolque tipo Plataforma'; // O puedes cambiarlo por el que venga desde la API si lo deseas
  Map<String, dynamic> especificaciones = {}; // Aquí se cargan los datos reales

  final Map<String, bool> _expandedMainSections = {
    'Especificaciones Técnicas': true,
    'Adicionales': true,
  };

  final Map<String, List<String>> categorias = {
    'SERVICIOS GENERALES': [
      'PAQUETERIA DE UN SISTEMA DE AUTOINFLADO P/2 EJES',
      'SERVICIO DE CORTE DE BARRASPARA LWCD',
      'SERVICIO DE CORTE KIT DE BARRAS PARA TOLVA 16M3 SERVIACERO',
      'BUJES SOBRE SOVREMOTOR',
      'BIRLOS Y TUERCAS FLOTANTES P7MONTACARGAS',
    ],
    'MAQUINADO BARRAS TOLVA 30M3': [
      'CORTE, CALIBRAR DIAM. INT. 2 1/8" BH LONG 200MM',
      'CORTE, CALIBRAR DIAM. INT. 2" BH LONG 200MM',
      'CORTE, CALIBRAR DIAM. INT. 3" BH LONG 150MM GRASERA',
      'CORTE, CALIBRAR DIAM. INT. 1" BH LONG 50MM',
    ],
  };

  //Map<String, bool> _expandedCategorias = {};
  final List<String> _adicionalesSeleccionados = [];
  final Map<String, Set<String>> _excludedFeatures = {};
  final List<String> adicionales = [];
  final TextEditingController _adicionalesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
    _cargarDatosModeloSeleccionado();
  }

  @override
  void dispose() {
    _adicionalesController.dispose();
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
                StepHeaderBar(pasoActual: 2, totalPasos: 4), // <-- Fuera del scroll
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
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center, // Centra los botones
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
                            const SizedBox(width: 32), // Espacio entre los botones
                            SizedBox(
                              width: 140,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/seccion3');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white, // <-- Igual que "Atrás"
                                  foregroundColor: Colors.black, // <-- Igual que "Atrás"
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

      if (sectionContent is Map<String, dynamic>) {
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
                              .map<Widget>((item) => Text('• $item'))
                              .toList(),
                        )
                      : Text(value.toString()),
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

  String? _categoriaExpandida; // Controla qué categoría está abierta
  Widget _buildAdicionalesCarrito() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 24),
      child: ExpansionTile(
        initiallyExpanded: true, // Inicialmente expandido
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
                // Contenedor único para el menú
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      // Botón principal
                      ListTile(
                        title: Text(
                          _categoriaExpandida == null
                              ? "Agregar adicionales"
                              : _categoriaExpandida!.isEmpty
                              ? "Seleccionar categoría"
                              : _categoriaExpandida!,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        trailing: Icon(
                          _categoriaExpandida == null
                              ? Icons.expand_more
                              : Icons.expand_less,
                          color: Colors.blue.shade800,
                        ),
                        onTap: () {
                          setState(() {
                            _categoriaExpandida = _categoriaExpandida == null
                                ? ''
                                : null;
                          });
                        },
                      ),

                      // Menú desplegable
                      if (_categoriaExpandida != null)
                        _buildMenuAdicionalesSimplificado(),
                    ],
                  ),
                ),

                // Lista de seleccionados (solo si hay elementos)
                if (_adicionalesSeleccionados.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    "Adicionales seleccionados:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _adicionalesSeleccionados
                        .map(
                          (item) => Chip(
                            label: Text(
                              item,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(
                                () => _adicionalesSeleccionados.remove(item),
                              );
                            },
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ADICIONALES
  Widget _buildMenuAdicionalesSimplificado() {
    // Mostrar categorías principales
    if (_categoriaExpandida == '') {
      return Column(
        children: categorias.keys.map((categoria) {
          return ListTile(
            contentPadding: const EdgeInsets.only(left: 32, right: 16),
            title: Text(categoria),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {
              setState(() {
                _categoriaExpandida = categoria;
              });
            },
          );
        }).toList(),
      );
    }

    // Mostrar items de la categoría seleccionada
    return Column(
      children: [
        // Botón de retroceso
        ListTile(
          contentPadding: const EdgeInsets.only(left: 16, right: 16),
          leading: const Icon(Icons.arrow_back, size: 20),
          title: Text(
            'Volver a categorías',
            style: TextStyle(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: () {
            setState(() {
              _categoriaExpandida = '';
            });
          },
        ),

        // Items de la categoría
        ...categorias[_categoriaExpandida]!.map((item) {
          final isSelected = _adicionalesSeleccionados.contains(item);
          return ListTile(
            contentPadding: const EdgeInsets.only(left: 32, right: 16),
            title: Text(
              item,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? Colors.blue.shade800 : Colors.black87,
              ),
            ),
            trailing: Icon(
              isSelected ? Icons.check_circle : Icons.add_circle_outline,
              color: isSelected ? Colors.green : Colors.grey,
              size: 20,
            ),
            onTap: () {
              setState(() {
                if (isSelected) {
                  _adicionalesSeleccionados.remove(item);
                } else {
                  _adicionalesSeleccionados.add(item);
                }
              });
            },
          );
        }),
      ],
    );
  }


  Widget _buildLoader() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
      ),
    );
  }
}

// Progress bar widget for steps
class StepHeaderBar extends StatelessWidget {
  final int pasoActual;
  final int totalPasos;

  const StepHeaderBar({required this.pasoActual, required this.totalPasos, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Línea amarilla sobre fondo negro
        Stack(
          children: [
            Container(
              width: double.infinity,
              height: 6,
              color: Colors.black,
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pasoActual / totalPasos,
              child: Container(
                height: 6,
                color: const Color(0xFFD9CF6A),
              ),
            ),
          ],
        ),
        Container(
          width: double.infinity,
          color: const Color(0xFF386AC7),
          padding: const EdgeInsets.symmetric(vertical: 8), // Menos padding
          child: Center(
            child: Text(
              'Paso $pasoActual de $totalPasos',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18, 
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}