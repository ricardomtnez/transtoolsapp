import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transtools/models/usuario.dart';


class Seccion1 extends StatefulWidget {
  // ignore: use_super_parameters
  const Seccion1({Key? key}) : super(key: key);
  @override
  State<Seccion1> createState() => _Seccion1();
}

class _Seccion1 extends State<Seccion1> {
  Usuario? _usuario; // Variable para guardar el usuario cargado
  var cotizacionCtrl = TextEditingController();
  final nombreCtrl = TextEditingController();
  final empresaCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();
  final correoCtrl = TextEditingController();
  final fechaCtrl = TextEditingController();
  final largoCtrl = TextEditingController();
  final anchoCtrl = TextEditingController();
  final altoCtrl = TextEditingController();
  String? vigenciaSeleccionada;

  String? productoSeleccionado;
  String? categoriaSeleccionada;
  String? lineaSeleccionada;
  String? modeloSeleccionado;
  String? yearSeleccionado;
  String? ejesSeleccionados;

  bool get _modeloDisponible {
  return productoSeleccionado != null &&
         lineaSeleccionada != null &&
         ejesSeleccionados != null;
}

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
    fechaCtrl.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
  }

  @override
  void dispose() {
    cotizacionCtrl.dispose();
    nombreCtrl.dispose();
    empresaCtrl.dispose();
    telefonoCtrl.dispose();
    correoCtrl.dispose();
    fechaCtrl.dispose();
    super.dispose();
  }
  void _irASiguiente() {
    if (cotizacionCtrl.text.isEmpty ||
        fechaCtrl.text.isEmpty ||
        vigenciaSeleccionada == null ||
        nombreCtrl.text.isEmpty ||
        empresaCtrl.text.isEmpty ||
        telefonoCtrl.text.isEmpty ||
        correoCtrl.text.isEmpty) {
      mostrarAlertaError(
        context,
        'Por favor llena todos los campos obligatorios',
      );
      return;
    }
    Navigator.pushNamed(context, '/seccion2');
  }

  void mostrarAlertaError(BuildContext context, String mensaje) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text(mensaje),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              textStyle: TextStyle(color: CupertinoColors.systemBlue),
              child: const Text(
                'Aceptar',
              ),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Aceptar',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _cargarUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('usuario');
    if (jsonString != null) {
      setState(() {
        _usuario = Usuario.fromJson(
          jsonString,
        ); // Ya devuelve un objeto Usuario
        final mesActual = DateTime.now().month.toString().padLeft(2, '0');
        cotizacionCtrl.text  = 'COT-${_usuario!.initials}$mesActual-';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[800],
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
          'Nueva cotización',
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
                    _usuario!.fullname,
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
                  ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: const Text('Cotizador'),
                    onTap: () {
                      Navigator.pushNamed(context, '/seccion1');
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

      body: Column(
        children: [
          // Barra de progreso
          LinearProgressIndicator(
            value: 1 / 3, //
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
            valueColor: AlwaysStoppedAnimation<Color>(
              const Color.fromARGB(255, 210, 198, 59),
            ),
            minHeight: 6,
          ),
          const SizedBox(height: 8),
          const Text(
            'Paso 1 de 3',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // El contenido scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSection(
                    title: 'Información Inicial',
                    children: [
                      _CustomTextField(
                        controller: cotizacionCtrl,
                        hint: 'Número de Cotización',
                        enabled: false,
                      ),
                      _CustomTextField(
                        controller: fechaCtrl,
                        hint: 'Fecha de cotización',
                        enabled: false,
                      ),
                      _VigenciaDropdown(
                        valorSeleccionado: vigenciaSeleccionada,
                        onChanged: (value) {
                          setState(() {
                            vigenciaSeleccionada = value;
                          });
                        },
                      ),
                    ],
                  ),
                  _buildSection(
                    title: 'Información del Cliente',
                    children: [
                      _CustomTextField(controller: nombreCtrl, hint: 'Nombre'),
                      _CustomTextField(
                        controller: empresaCtrl,
                        hint: 'Empresa',
                      ),
                      _CustomTextField(
                        controller: telefonoCtrl,
                        hint: 'Telefono',
                      ),
                      _CustomTextField(
                        controller: correoCtrl,
                        hint: 'Correo Electronico',
                      ),
                    ],
                  ),
                  _buildSection(
  title: 'Producto',
  children: [
    _ProductoDropdown(
      value: productoSeleccionado,
      onChanged: (v) => setState(() {
        productoSeleccionado = v;
        modeloSeleccionado = null; 
      }),
    ),
  ],
),
                  _buildSection(
                    title: 'Linea',
                    children: [
                      _LineaDropdown(
                        value: lineaSeleccionada,
                        onChanged: (v) => setState(() => lineaSeleccionada = v),
                      ),
                    ],
                  ),
                  _buildSection(
                      title: 'Ejes',
                      children: [
                        NumeroEjesDropdown(
                          value: ejesSeleccionados,
                          onChanged: (v) => setState(() => ejesSeleccionados = v),
                        ),
                      ],
                    ),
                  // Aquí se determina si el modelo está disponible

                    _buildSection(
                    title: 'Modelo/Gama',
                    children: [
                      _ModeloDropdown(
                        value: modeloSeleccionado,
                        enabled: _modeloDisponible, // ← activa o desactiva el dropdown
                        onChanged: (v) => setState(() => modeloSeleccionado = v),
                      ),
                    ],
                  ),
                  _buildSection(
                    title: 'Edición',
                    children: [
                      _YearPickerField(
                        initialYear: yearSeleccionado,
                        onYearSelected: (year) {
                          setState(() {
                            yearSeleccionado = year;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _NavigationButton(
                        label: 'Atras',
                        onPressed: () {
                          Navigator.pushNamed(context, '/dashboard');
                        },
                      ),
                      _NavigationButton(
                        label: 'Siguiente',
                        onPressed: _irASiguiente,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool enabled;

  const _CustomTextField({
    required this.hint,
    required this.controller,
    this.enabled = true, 
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          enabled: enabled,
          filled: true,
          fillColor: Colors.grey[200],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );
  }
}

Widget _buildDropdown(
  BuildContext context,
  String? value,
  void Function(String?) onChanged,
  List<String> options,
) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 6),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(30),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isExpanded: true,
        value: value,
        hint: const Text('Selecciona una opción'),
        onChanged: onChanged,
        items: options
            .map(
              (option) => DropdownMenuItem(value: option, child: Text(option)),
            )
            .toList(),
      ),
    ),
  );
}

class _ProductoDropdown extends StatefulWidget {
  final String? value;
  final void Function(String?) onChanged;

  const _ProductoDropdown({required this.value, required this.onChanged});

  @override
  State<_ProductoDropdown> createState() => _ProductoDropdownState();
}

class _ProductoDropdownState extends State<_ProductoDropdown> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<String> _filteredProductos = [];

static const List<String> _productos = [
  'PLATAFORMA ESTANDAR',
  'PLATAFORMA SLIM DECK',
  'PLATAFORMAS ESPECIALES',
  'DOLLY A',
  'VOLTEO ESTANDAR',
  'VOLTEO AUTOMOTRIZ',
  'VOLTEOS ESPECIALES',
  'LOWBOY CUELLO FIJO',
  'LOWBOY CUELLO DESMONTABLE',
  'LOWBOY CUELLO DESMONTABLE EXTENDIBLE',
  'JEEP DOLLY',
  'CHASIS PORTA CONTENEDOR',
  'CHASIS PORTA CONTENEDOR EXTENDIBLE',
  'ENCORTINADO TIPO TUNEL',
  'ENCORTINADO TIPO CERVECERO',
  'ENCORTINADO AUTOMOTRIZ/ESPECIALES',
  'DOLLY H',
  'JAULA',
  'ISOTANQUE',
];

  @override
  void initState() {
    super.initState();
    _filteredProductos = _productos;
    if (widget.value != null) {
      _controller.text = widget.value!;
    }

    _focusNode.addListener(_handleFocusChange);
    _controller.addListener(_handleTextChange);
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _handleTextChange() {
    _filterOptions(_controller.text);
  }

  void _filterOptions(String query) {
    setState(() {
      _filteredProductos = _productos.where((producto) {
        return producto.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
    
    // Actualizar el overlay si existe
    _overlayEntry?.markNeedsBuild();
  }

  void _showOverlay() {
    // Asegurarse de remover cualquier overlay existente
    _removeOverlay();
    
    // Obtener el render box después de que el widget esté construido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null || !mounted) return;

      _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          width: renderBox.size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, renderBox.size.height + 5),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
                constraints: BoxConstraints(
                  maxHeight: 200, // En pixeles
                ),
                child: _filteredProductos.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No se encontraron coincidencias',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: _filteredProductos.length,
                        itemBuilder: (context, index) {
                          final option = _filteredProductos[index];
                          return InkWell(
                            onTap: () {
                              _controller.text = option;
                              widget.onChanged(option);
                              _focusNode.unfocus();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: _controller.text == option
                                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _controller.text == option 
                                      ? Theme.of(context).primaryColor 
                                      : Colors.black,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ),
      );

      if (mounted) {
        Overlay.of(context).insert(_overlayEntry!);
      }
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _controller.removeListener(_handleTextChange);
    _focusNode.dispose();
    _controller.dispose();
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: () {
          if (_focusNode.hasFocus) {
            _focusNode.unfocus();
          } else {
            _focusNode.requestFocus();
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(29),
            border: Border.all(
              color: _focusNode.hasFocus 
                  ? Theme.of(context).primaryColor 
                  : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: const InputDecoration(
                    hintText: 'Selecciona un producto',
                    hintStyle: TextStyle(color: Color.fromARGB(255, 64, 64, 64)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
              Icon(
                _focusNode.hasFocus ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: const Color.fromARGB(255, 86, 86, 86),
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _LineaDropdown extends StatelessWidget {
  final String? value;
  final void Function(String?) onChanged;
  const _LineaDropdown({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return _buildDropdown(context, value, onChanged, [
    'Titanium Fleet Max', 
    'Titanium AMForce', 
    'Titanium Elite', 
    'Titanium HRP',
    ]);
  }
}


class NumeroEjesDropdown extends StatelessWidget {
  final String? value;
  final void Function(String?) onChanged;

  const NumeroEjesDropdown({super.key, 
    required this.value,
    required this.onChanged,
  });

  static const List<String> _opciones = [
    '1 Eje',
    '2 Eje',
    '3 Eje',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(29),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _opciones.contains(value) ? value : null,
          isExpanded: true,
          hint: const Text(
            'Selecciona una opción',
            style: TextStyle(color: Color(0xFF404040)),
          ),
          icon: const Icon(
            Icons.arrow_drop_down,
            color: Color(0xFF565656),
          ),
          items: _opciones.map((opcion) {
            return DropdownMenuItem<String>(
              value: opcion,
              child: Text(opcion),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ModeloDropdown extends StatelessWidget {
  final String? value;
  final void Function(String?)? onChanged;
  final bool enabled;

  const _ModeloDropdown({
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  static const List<String> _modelos = [
    'MODELO A', 
    'MODELO B', 
    'MODELO C', 
    'MODELO D',
  ];

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(29),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _modelos.any((item) => item == value) ? value : null,
              isExpanded: true,
              hint: const Text(
                'Selecciona una opción',
                style: TextStyle(color: Color(0xFF404040)),
              ),
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Color(0xFF565656),
              ),
              items: _modelos.map((modelo) {
                return DropdownMenuItem<String>(
                  value: modelo,
                  child: Text(modelo),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
  }
}

class _VigenciaDropdown extends StatelessWidget {
  final String? valorSeleccionado;
  final void Function(String?) onChanged;

  const _VigenciaDropdown({
    required this.valorSeleccionado,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: valorSeleccionado,
          hint: const Text('Selecciona vigencia (días)'),
          onChanged: onChanged,
          items: const [
            DropdownMenuItem(value: '1', child: Text('1 día')),
            DropdownMenuItem(value: '7', child: Text('7 días')),
            DropdownMenuItem(value: '15', child: Text('15 días')),
            DropdownMenuItem(value: '30', child: Text('30 días')),
          ],
        ),
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _NavigationButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

/// Widget para seleccionar un año (modelo)
class _YearPickerField extends StatelessWidget {
  final String? initialYear;
  final void Function(String) onYearSelected;

  const _YearPickerField({
    required this.initialYear,
    required this.onYearSelected,
  });

  List<String> _getYears() {
    final currentYear = DateTime.now().year;
    return List.generate(30, (i) => (currentYear - i).toString());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: initialYear,
          hint: const Text('Selecciona el año del modelo'),
          menuMaxHeight: 200,
          onChanged: (value) {
            if (value != null) {
              onYearSelected(value);
            }
          },
          items: _getYears()
              .map((year) => DropdownMenuItem(
                    value: year,
                    child: Text(year),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
