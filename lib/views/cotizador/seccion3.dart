import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';

class Seccion3 extends StatefulWidget {
  const Seccion3({super.key});

  @override
  _Seccion3State createState() => _Seccion3State();
}

class _Seccion3State extends State<Seccion3> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController direccionEntregaController = TextEditingController();
  final TextEditingController receptorController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController correoController = TextEditingController();
  final TextEditingController unidadesController = TextEditingController();

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

  final List<String> formasPago = ['Contado', 'Crédito',];
  final List<String> metodosPago = ['Efectivo', 'Transferencia','Tarjeta', 'Cheque', 'Otro'];
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
        body: SafeArea(
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
                        onChanged: (value) => setState(() => formaPago = value),
                        validator: (value) => value == null ? 'Seleccione una forma de pago' : null,
                      ),
                      _styledDropdown(
                        label: 'Método de Pago',
                        value: metodoPago,
                        items: metodosPago,
                        onChanged: (value) => setState(() => metodoPago = value),
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
                          onChanged: (value) {
                          },
                          validator: (value) => value == null ? 'Seleccione una cuenta' : null,
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
                          'Inicio: ${fechaInicio!.day}/${fechaInicio!.month}/${fechaInicio!.year}\n'
                              'Fin: ${fechaFin!.day}/${fechaFin!.month}/${fechaFin!.year}\n'
                              'Tiempo de entrega: $semanasEntrega semanas a partir de su anticipo',
                        )
                            : const Text('No se ha seleccionado un rango'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          if (Platform.isIOS) {
                            // Muestra un CupertinoDatePicker en pantalla completa para iOS
                            DateTime? start;
                            DateTime? end;
                            await showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) {
                                DateTime now = DateTime.now();
                                DateTime minDate = DateTime(now.year, now.month, now.day);

                                DateTime tempStart = fechaInicio ?? minDate;
                                DateTime tempEnd = fechaFin ?? minDate.add(const Duration(days: 7));

                                return SafeArea(
                                  child: Container(
                                    height: MediaQuery.of(context).size.height * 0.85,
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('Selecciona la fecha de inicio'),
                                        CupertinoDatePicker(
                                          mode: CupertinoDatePickerMode.date,
                                          initialDateTime: tempStart,
                                          minimumDate: minDate,
                                          maximumDate: minDate.add(const Duration(days: 365)),
                                          onDateTimeChanged: (date) {
                                            tempStart = DateTime(date.year, date.month, date.day);
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        const Text('Selecciona la fecha de fin'),
                                        CupertinoDatePicker(
                                          mode: CupertinoDatePickerMode.date,
                                          initialDateTime: tempEnd,
                                          minimumDate: minDate,
                                          maximumDate: minDate.add(const Duration(days: 365)),
                                          onDateTimeChanged: (date) {
                                            tempEnd = DateTime(date.year, date.month, date.day);
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue[800],
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(30),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                            textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          onPressed: () {
                                            Navigator.pop(context, [tempStart, tempEnd]);
                                          },
                                          child: const Text('Aceptar'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ).then((result) {
                              if (result != null && result is List<DateTime> && result.length == 2) {
                                setState(() {
                                  fechaInicio = result[0];
                                  fechaFin = result[1];
                                  final dias = fechaFin!.difference(fechaInicio!).inDays;
                                  semanasEntrega = (dias / 7).ceil().toString();
                                });
                              }
                            });
                          } else {
                            // Android y otros: showDateRangePicker
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
          ...children, // <--- Solo los children, sin Form aquí
        ],
      ),
    );
  }

  Widget _styledDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    FormFieldValidator<String>? validator,
  }) {
    // Detecta si es el dropdown de cuentas por el label
    final bool isCuentas = label.contains('Cuenta');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 240, 240, 240),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
        ),
        selectedItemBuilder: (context) => items.map((item) {
          // Solo aplica el Tooltip y ellipsis para cuentas
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
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }
}
