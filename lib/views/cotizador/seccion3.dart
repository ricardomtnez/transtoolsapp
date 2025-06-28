import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:transtools/models/usuario.dart';
import 'package:shared_preferences/shared_preferences.dart';


class Seccion3 extends StatefulWidget {
  final String? unidades;
  final String? formaPago;


  const Seccion3({
    super.key,
    this.unidades,
    this.formaPago,

  });

  @override
  // ignore: library_private_types_in_public_api
  _Seccion3State createState() => _Seccion3State();
}

class _Seccion3State extends State<Seccion3> {
  final _formKey = GlobalKey<FormState>();

  Usuario? _usuario;

  // Controllers
  final TextEditingController direccionEntregaController = TextEditingController();
  final TextEditingController receptorController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController correoController = TextEditingController();
  final TextEditingController unidadesController = TextEditingController();
  final TextEditingController otroMetodoController = TextEditingController();

  String? formaPago;
  String? metodoPago;
  String? plazoPago;
  String? moneda;
  String? entregaEn;
  String? tiempoEntrega;
  String? garantia;
  String? cuentaSeleccionada;

  DateTime? fechaInicio;
  DateTime? fechaFin;
  String? semanasEntrega;

  final List<String> formasPago = ['Contado'];
  final List<String> metodosPago = ['Transferencia', 'Cheque', 'Otro'];
  final List<String> monedas = ['MXN', 'USD'];
  final List<String> tiemposEntrega = [
    '4 semanas a partir de su anticipo',
    '6 semanas a partir de su anticipo',
    '8 semanas a partir de su anticipo',
  ];
  final List<String> garantias = [
    '6 meses', 
    '12 meses',
  ];
  final List<String> cuentasMXN = [
    'BBVA Bancomer - 123456789 - Clabe: 012345678901234567',
    'Santander - 123456789 - Clabe: 002180123456789012',
  ];
  final List<String> cuentasUSD = [
    'BBVA Bancomer USD - 987654321 - Clabe: 012345678901234568',
    'Santander USD - 987654321 - Clabe: 002180123456789013',
  ];

   
  @override
  void initState() {
    super.initState();
    _cargarUsuario();
    formaPago = 'Contado'; // <-- Valor por default y fijo
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.blue[800],
        appBar: AppBar(
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black),
          title: const Text(
            'Datos de Pago y Entrega',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
      ), // <--- Agrega aquí tu Drawer personalizado
        body: SafeArea(
          child: Column(
            children: [
              // Progress bar personalizado
              Stack(
                children: [
                  Container(
                    height: 8,
                    color: const Color.fromARGB(255, 0, 0, 0), 
                  ),
                  FractionallySizedBox(
                    widthFactor: 0.75, 
                    child: Container(
                      height: 8,
                      color: const Color(0xFFD9CF6A), // Barra de progreso
                    ),
                  ),
                ],
              ),
              Container(
                width: double.infinity,
                color: Colors.blue[800],
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: const Center(
                  child: Text(
                    'Paso 3 de 4', // Cambia el número según el paso
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              // El resto de tu contenido:
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Panel de número de unidades
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Número de unidades',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  final current = int.tryParse(unidadesController.text) ?? 0;
                                  if (current > 1) {
                                    unidadesController.text = (current - 1).toString();
                                    setState(() {});
                                  }
                                },
                              ),
                              SizedBox(
                                width: 60,
                                child: TextFormField(
                                  controller: unidadesController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly, // <-- Solo permite números
                                  ],
                                  decoration: const InputDecoration(
                                    hintText: '0',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(12)),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '';
                                    }
                                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                                      return '';
                                    }
                                    return null;
                                  },
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () {
                                  final current = int.tryParse(unidadesController.text) ?? 0;
                                  unidadesController.text = (current + 1).toString();
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        ),
                        _buildSection(
                          title: "Información de Pago",
                          children: [
                            _styledDropdown(
                              label: 'Forma de Pago',
                              value: formaPago,
                              items: formasPago,
                              onChanged: null, // <-- Esto lo deshabilita completamente
                              validator: (value) => value == null ? 'Seleccione una forma de pago' : null,
                            ),
                            _styledDropdown(
                              label: 'Método de Pago',
                              value: metodoPago,
                              items: metodosPago,
                              onChanged: (value) {
                                setState(() {
                                  metodoPago = value;
                                  moneda = null; 
                                  cuentaSeleccionada = null;
                                  otroMetodoController.clear(); 
                                });
                              },
                            ),
                            _styledDropdown(
                              label: 'Moneda',
                              value: moneda,
                              items: monedas,
                              onChanged: (value) {
                                setState(() {
                                  moneda = value;
                                  cuentaSeleccionada = null; 
                                });
                              },
                            ),
                            if (metodoPago == 'Transferencia' && moneda != null)
                              _styledDropdown(
                                label: 'Cuenta para Transferencia',
                                value: cuentaSeleccionada,
                                items: moneda == 'MXN' ? cuentasMXN : cuentasUSD,
                                onChanged: (value) => setState(() => cuentaSeleccionada = value),
                                validator: (value) => value == null ? 'Seleccione una cuenta' : null,
                              ),
                            if (metodoPago == 'Otro')
                              Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 240, 240, 240),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      // ignore: deprecated_member_use
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: otroMetodoController,
                                  decoration: InputDecoration(
                                    labelText: 'Especifique el método de pago',
                                    labelStyle: const TextStyle(
                                      color: Color(0xFF1565C0),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    border: InputBorder.none,
                                    suffixIcon: otroMetodoController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear, size: 22, color: Colors.grey),
                                            onPressed: () {
                                              otroMetodoController.clear();
                                              setState(() {});
                                            },
                                            splashRadius: 18,
                                          )
                                        : null,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  validator: (value) {
                                    if (metodoPago == 'Otro' && (value == null || value.isEmpty)) {
                                      return 'Ingrese el método de pago';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                          ],
                        ),
                        _buildSection(
                          title: "Información de Entrega",
                          children: [
                            ListTile(
                              title: const Text('Seleccionar rango de entrega'),
                              subtitle: semanasEntrega != null && fechaInicio != null && fechaFin != null
                                  ? Text(
                                    'Tiempo de entrega: $semanasEntrega semanas a partir de su anticipo',
                              )
                                  : const Text('No se ha seleccionado un rango'),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: () async {
                                final rango = await showDateRangePicker(
                                  context: context,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (rango != null) {
                                  setState(() {
                                    fechaInicio = rango.start;
                                    fechaFin = rango.end;
                                    final dias = fechaFin!.difference(fechaInicio!).inDays;
                                    semanasEntrega = (dias / 7).ceil().toString();
                                  });
                                }
                              },
                            ),
                            _styledDropdown(
                              label: 'Entrega en',
                              value: entregaEn,
                              items: const ['En Planta', 'Acordar con el cliente'],
                              onChanged: (value) => setState(() => entregaEn = value),
                              validator: (value) => value == null ? 'Seleccione una opción' : null,
                            ),
                            _styledDropdown(
                              label: 'Garantía',
                              value: garantia,
                              items: garantias,
                              onChanged: (value) => setState(() => garantia = value),
                              validator: (value) => value == null ? 'Seleccione una opción' : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SizedBox(
                              width: 140,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
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
                                child: const Text('Atras'),
                              ),
                            ),
                            SizedBox(
                              width: 140,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    // Navigator.pushNamed(context, "/seccion4");
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
                      ],
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

  Widget _buildSection({required String title, required List<Widget> children}) {
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

  Widget _styledDropdown({
    required String label,
    required String? value,
    required List<String> items,
    void Function(String?)? onChanged, // <-- Cambia aquí
    FormFieldValidator<String>? validator,
  }) {
    final bool isCuentas = label.contains('Cuenta');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 240, 240, 240),
        borderRadius: BorderRadius.circular(20), // Bordes redondeados
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.blue[800],
            fontWeight: FontWeight.bold,
          ),
          border: InputBorder.none,
        ),
        selectedItemBuilder: (context) => items.map((item) {
          return Tooltip(
            message: item,
            child: Container(
              alignment: Alignment.centerLeft,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(color: Colors.black),
              ),
            ),
          );
        }).toList(),
        items: items.map((item) => DropdownMenuItem(
          value: item,
          child: Padding(
            padding: isCuentas
                ? const EdgeInsets.symmetric(vertical: 10.0)
                : EdgeInsets.zero,
            child: Text(item),
          ),
        )).toList(),
        onChanged: onChanged, // <-- Así acepta null
        validator: validator,
        dropdownColor: Colors.white, // <-- Fondo blanco en la lista desplegable
        borderRadius: BorderRadius.circular(20), // <-- Bordes redondeados en la lista
      ),
    );
  }
}