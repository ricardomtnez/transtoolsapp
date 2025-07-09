import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:transtools/models/cotizacion.dart';
import 'package:transtools/models/usuario.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Seccion3 extends StatefulWidget {
  final String? unidades;
  final String? formaPago;
  final Cotizacion cotizacion;

  const Seccion3({
    super.key,
    this.unidades,
    this.formaPago,
    required this.cotizacion,
  });

  @override
  // ignore: library_private_types_in_public_api
  _Seccion3State createState() => _Seccion3State();
}

class _Seccion3State extends State<Seccion3> {
  final _formKey = GlobalKey<FormState>();

  Usuario? _usuario;
  // Controllers
  final TextEditingController direccionEntregaController =
      TextEditingController();
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
  final List<String> garantias = ['6 meses', '12 meses'];
  final List<String> cuentasMXN = [
    'BBVA Bancomer - 123456789 - Clabe: 012345678901234567',
    'Santander - 123456789 - Clabe: 002180123456789012',
  ];
  final List<String> cuentasUSD = [
    'BBVA Bancomer USD - 987654321 - Clabe: 012345678901234568',
    'Santander USD - 987654321 - Clabe: 002180123456789013',
  ];

  bool metodoPagoError = false;
  String? metodoPagoErrorText;

  bool monedaError = false;
  String? monedaErrorText;

  bool cuentaError = false;
  String? cuentaErrorText;

  bool entregaEnError = false;
  String? entregaEnErrorText;

  bool garantiaError = false;
  String? garantiaErrorText;

  bool rangoEntregaError = false;
  String? rangoEntregaErrorText;

  bool unidadesError = false;
  String? unidadesErrorText;

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
                            border: Border.all(
                              color: unidadesError
                                  ? Colors.red
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Número de unidades',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                    onPressed: () {
                                      final current =
                                          int.tryParse(
                                            unidadesController.text,
                                          ) ??
                                          0;
                                      if (current > 1) {
                                        unidadesController.text = (current - 1)
                                            .toString();
                                        setState(() {
                                          unidadesError = false;
                                          unidadesErrorText = null;
                                        });
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
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: const InputDecoration(
                                        hintText: '0',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(12),
                                          ),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 0,
                                        ),
                                      ),
                                      onChanged: (_) {
                                        setState(() {
                                          unidadesError = false;
                                          unidadesErrorText = null;
                                        });
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () {
                                      final current =
                                          int.tryParse(
                                            unidadesController.text,
                                          ) ??
                                          0;
                                      unidadesController.text = (current + 1)
                                          .toString();
                                      setState(() {
                                        unidadesError = false;
                                        unidadesErrorText = null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              if (unidadesError && unidadesErrorText != null)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 4,
                                    top: 4,
                                  ),
                                  child: Text(
                                    unidadesErrorText!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 13,
                                    ),
                                  ),
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
                              onChanged:
                                  null, // <-- Esto lo deshabilita completamente
                              validator: (value) => value == null
                                  ? 'Seleccione una forma de pago'
                                  : null,
                            ),
                            _styledDropdown(
                              label: 'Método de Pago',
                              value: metodoPago,
                              items: metodosPago,
                              onChanged: (value) {
                                setState(() {
                                  metodoPago = value;
                                  metodoPagoError = false;
                                  metodoPagoErrorText = null;
                                  moneda = null;
                                  cuentaSeleccionada = null;
                                  otroMetodoController.clear();
                                });
                              },
                              error: metodoPagoError,
                              errorText: metodoPagoErrorText,
                              showClear: metodoPago != null,
                              onClear: () {
                                setState(() {
                                  metodoPago = null;
                                  metodoPagoError = false;
                                  metodoPagoErrorText = null;
                                  moneda = null;
                                  cuentaSeleccionada = null;
                                  otroMetodoController.clear();
                                });
                              },
                            ),
                            if (metodoPago == 'Transferencia' ||
                                metodoPago == 'Cheque')
                              _styledDropdown(
                                label: 'Moneda',
                                value: moneda,
                                items: monedas,
                                onChanged: (value) {
                                  setState(() {
                                    moneda = value;
                                    monedaError = false;
                                    monedaErrorText = null;
                                    cuentaSeleccionada = null;
                                  });
                                },
                                error: monedaError,
                                errorText: monedaErrorText,
                                showClear: moneda != null,
                                onClear: () {
                                  setState(() {
                                    moneda = null;
                                    monedaError = false;
                                    monedaErrorText = null;
                                    cuentaSeleccionada = null;
                                  });
                                },
                              ),
                            if (metodoPago == 'Transferencia' && moneda != null)
                              _styledDropdown(
                                label: 'Cuenta para Transferencia',
                                value: cuentaSeleccionada,
                                items: moneda == 'MXN'
                                    ? cuentasMXN
                                    : cuentasUSD,
                                onChanged: (value) {
                                  setState(() {
                                    cuentaSeleccionada = value;
                                    cuentaError = false;
                                    cuentaErrorText = null;
                                  });
                                },
                                error: cuentaError,
                                errorText: cuentaErrorText,
                                showClear: cuentaSeleccionada != null,
                                onClear: () {
                                  setState(() {
                                    cuentaSeleccionada = null;
                                    cuentaError = false;
                                    cuentaErrorText = null;
                                  });
                                },
                                validator: (value) => value == null
                                    ? 'Seleccione una cuenta'
                                    : null,
                              ),
                            if (metodoPago == 'Otro')
                              Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(
                                    255,
                                    240,
                                    240,
                                    240,
                                  ),
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
                                    suffixIcon:
                                        otroMetodoController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(
                                              Icons.clear,
                                              size: 22,
                                              color: Colors.grey,
                                            ),
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
                                    if (metodoPago == 'Otro' &&
                                        (value == null || value.isEmpty)) {
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
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 240, 240, 240),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: rangoEntregaError
                                      ? Colors.red
                                      : Colors.grey[300]!,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      'Seleccionar rango de entrega',
                                      style: TextStyle(
                                        color:
                                            (semanasEntrega != null &&
                                                fechaInicio != null &&
                                                fechaFin != null)
                                            ? const Color(0xFF1565C0) // Azul
                                            : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle:
                                        (semanasEntrega != null &&
                                            fechaInicio != null &&
                                            fechaFin != null)
                                        ? Text(
                                            'Tiempo de entrega: $semanasEntrega semanas a partir de su anticipo',
                                            style: const TextStyle(
                                              color: Color.fromARGB(
                                                255,
                                                0,
                                                0,
                                                0,
                                              ), // Azul
                                              fontWeight: FontWeight.w500,
                                            ),
                                          )
                                        : const Text(
                                            'No se ha seleccionado un rango',
                                            style: TextStyle(
                                              color: Color(0xFF1565C0),
                                            ),
                                          ),
                                    trailing: const Icon(Icons.calendar_today),
                                    onTap: () async {
                                      final rango = await showDateRangePicker(
                                        context: context,
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now().add(
                                          const Duration(days: 365),
                                        ),
                                      );
                                      if (rango != null) {
                                        setState(() {
                                          fechaInicio = rango.start;
                                          fechaFin = rango.end;
                                          final dias = fechaFin!
                                              .difference(fechaInicio!)
                                              .inDays;
                                          semanasEntrega = (dias / 7)
                                              .ceil()
                                              .toString();
                                          rangoEntregaError = false;
                                          rangoEntregaErrorText = null;
                                        });
                                      }
                                    },
                                  ),
                                  if (rangoEntregaError &&
                                      rangoEntregaErrorText != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 12,
                                        top: 2,
                                      ),
                                      child: Text(
                                        rangoEntregaErrorText!,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            _styledDropdown(
                              label: 'Entrega en',
                              value: entregaEn,
                              items: const [
                                'En Planta',
                                'Acordar con el cliente',
                              ],
                              onChanged: (value) {
                                setState(() {
                                  entregaEn = value;
                                  entregaEnError = false;
                                  entregaEnErrorText = null;
                                });
                              },
                              error: entregaEnError,
                              errorText: entregaEnErrorText,
                              showClear: entregaEn != null,
                              onClear: () {
                                setState(() {
                                  entregaEn = null;
                                  entregaEnError = false;
                                  entregaEnErrorText = null;
                                });
                              },
                              validator: (value) => value == null
                                  ? 'Seleccione una opción'
                                  : null,
                            ),
                            _styledDropdown(
                              label: 'Garantía',
                              value: garantia,
                              items: garantias,
                              onChanged: (value) {
                                setState(() {
                                  garantia = value;
                                  garantiaError = false;
                                  garantiaErrorText = null;
                                });
                              },
                              error: garantiaError,
                              errorText: garantiaErrorText,
                              showClear: garantia != null,
                              onClear: () {
                                setState(() {
                                  garantia = null;
                                  garantiaError = false;
                                  garantiaErrorText = null;
                                });
                              },
                              validator: (value) => value == null
                                  ? 'Seleccione una opción'
                                  : null,
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
                                child: const Text('Atras'),
                              ),
                            ),
                            SizedBox(
                              width: 140,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    metodoPagoError = metodoPago == null;
                                    metodoPagoErrorText = metodoPagoError
                                        ? 'Seleccione un método de pago'
                                        : null;

                                    monedaError = moneda == null;
                                    monedaErrorText = monedaError
                                        ? 'Seleccione una moneda'
                                        : null;

                                    cuentaError =
                                        (metodoPago == 'Transferencia' &&
                                        cuentaSeleccionada == null);
                                    cuentaErrorText = cuentaError
                                        ? 'Seleccione una cuenta'
                                        : null;

                                    entregaEnError = entregaEn == null;
                                    entregaEnErrorText = entregaEnError
                                        ? 'Seleccione una opción'
                                        : null;

                                    garantiaError = garantia == null;
                                    garantiaErrorText = garantiaError
                                        ? 'Seleccione una opción'
                                        : null;

                                    rangoEntregaError =
                                        (fechaInicio == null ||
                                        fechaFin == null);
                                    rangoEntregaErrorText = rangoEntregaError
                                        ? 'Seleccione un rango de entrega'
                                        : null;

                                    unidadesError =
                                        unidadesController.text.isEmpty ||
                                        int.tryParse(unidadesController.text) ==
                                            null ||
                                        int.parse(unidadesController.text) <= 0;
                                    unidadesErrorText = unidadesError
                                        ? 'Ingrese un número válido de unidades'
                                        : null;
                                  });

                                  if (unidadesError ||
                                      metodoPagoError ||
                                      monedaError ||
                                      cuentaError ||
                                      entregaEnError ||
                                      garantiaError ||
                                      rangoEntregaError) {
                                    // Mostrar alerta o scroll al primer error
                                    return;
                                  }

                                  if (_formKey.currentState!.validate()) {
                                    // Siguiente paso
                                    // Actualiza el objeto cotización con los datos ingresados en esta sección:
                                    final cotizacionActualizada = widget
                                        .cotizacion
                                        .copyWith(
                                          numeroUnidades: int.tryParse(
                                            unidadesController.text,
                                          ),
                                          formaPago: formaPago,
                                          metodoPago: metodoPago,
                                          moneda: moneda,
                                          entregaEn: entregaEn,
                                          garantia: garantia,
                                          cuentaSeleccionada:
                                              cuentaSeleccionada,
                                          otroMetodoPago:
                                              otroMetodoController
                                                  .text
                                                  .isNotEmpty
                                              ? otroMetodoController.text
                                              : null,
                                          fechaInicioEntrega: fechaInicio,
                                          fechaFinEntrega: fechaFin,
                                          semanasEntrega: semanasEntrega,
                                          importe: widget.cotizacion.importe,
                                          totalAdicionales: widget
                                              .cotizacion
                                              .totalAdicionales,
                                        );

                                    // Navegar a la Sección 4 pasando el objeto cotización actualizado
                                    Navigator.pushNamed(
                                      context,
                                      '/seccion4',
                                      arguments: {
                                        'cotizacion': cotizacionActualizada,
                                      },
                                    );
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

  Widget _styledDropdown({
    required String label,
    required String? value,
    required List<String> items,
    void Function(String?)? onChanged,
    FormFieldValidator<String>? validator,
    bool error = false,
    String? errorText,
    bool showClear = false,
    VoidCallback? onClear,
  }) {
    final bool isCuentas = label.contains('Cuenta');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 240, 240, 240),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: error ? Colors.red : Colors.grey[300]!,
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
            color: error ? Colors.red : Colors.blue[800],
            fontWeight: FontWeight.bold,
          ),
          border: InputBorder.none,
          errorText: error ? errorText : null,
          errorStyle: const TextStyle(color: Colors.red, fontSize: 13),
          suffixIcon: showClear && value != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 22, color: Colors.grey),
                  onPressed: onClear,
                  splashRadius: 18,
                )
              : null,
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
        items: items
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Padding(
                  padding: isCuentas
                      ? const EdgeInsets.symmetric(vertical: 10.0)
                      : EdgeInsets.zero,
                  child: Text(item),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
        validator: validator,
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
