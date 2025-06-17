import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transtools/models/usuario.dart';

class Seccion1 extends StatefulWidget {
  const Seccion1({super.key});

  @override
  State<Seccion1> createState() => _Seccion1State();
}

class _Seccion1State extends State<Seccion1> {
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
              ), // child debe ser el último argumento
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
                        onChanged: (v) =>
                            setState(() => productoSeleccionado = v),
                      ),
                    ],
                  ),
                  _buildSection(
                    title: 'Categoria',
                    children: [
                      _CategoriaDropdown(
                        value: categoriaSeleccionada,
                        onChanged: (v) =>
                            setState(() => categoriaSeleccionada = v),
                      ),
                    ],
                  ),
                  _buildSection(
                    title: 'Linea/Clase',
                    children: [
                      _LineaDropdown(
                        value: lineaSeleccionada,
                        onChanged: (v) => setState(() => lineaSeleccionada = v),
                      ),
                    ],
                  ),
                  _buildSection(
                    title: 'Modelo',
                    children: [
                      _ModeloDropdown(
                        value: modeloSeleccionado,
                        onChanged: (v) =>
                            setState(() => modeloSeleccionado = v),
                      ),
                    ],
                  ),
                  _buildSection(
                    title: 'Dimensiones',
                    children: [
                      _CustomTextField(
                        controller: largoCtrl,
                        hint: 'Largo (m)',
                      ),
                      _CustomTextField(
                        controller: anchoCtrl,
                        hint: 'Ancho (m)',
                      ),
                      _CustomTextField(controller: altoCtrl, hint: 'Alto (m)'),
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
    this.enabled = true, // Por defecto está habilitado
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

class _ProductoDropdown extends StatelessWidget {
  final String? value;
  final void Function(String?) onChanged;
  const _ProductoDropdown({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return _buildDropdown(context, value, onChanged, [
      'Volteo',
      'Plataforma',
      'Caja Seca',
    ]);
  }
}

class _CategoriaDropdown extends StatelessWidget {
  final String? value;
  final void Function(String?) onChanged;
  const _CategoriaDropdown({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return _buildDropdown(context, value, onChanged, [
      'Semiremolque',
      'Carroceria',
    ]);
  }
}

class _LineaDropdown extends StatelessWidget {
  final String? value;
  final void Function(String?) onChanged;
  const _LineaDropdown({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return _buildDropdown(context, value, onChanged, ['Titanium', 'AMForce']);
  }
}

class _ModeloDropdown extends StatelessWidget {
  final String? value;
  final void Function(String?) onChanged;
  const _ModeloDropdown({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return _buildDropdown(context, value, onChanged, [
      'Volteo 30 m³',
      'Volteo 35 m³',
      'Volteo 40 m³',
    ]);
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
