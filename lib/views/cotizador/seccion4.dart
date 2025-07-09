import 'package:flutter/material.dart';
import 'package:transtools/models/cotizacion.dart';
import 'package:intl/intl.dart';

class Seccion4 extends StatelessWidget {
  final Cotizacion cotizacion;

  // Recibe la cotización en el constructor
  Seccion4({Key? key, required this.cotizacion}) : super(key: key);

  // Método estático para facilitar crear la ruta con argumentos
  static Route route(RouteSettings settings) {
    final args = settings.arguments as Map<String, dynamic>;
    return MaterialPageRoute(
      builder: (_) => Seccion4(cotizacion: args['cotizacion']),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[800],
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Resumen de Cotización',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitulo('Datos Generales'),
                _buildCard([
                  Table(
                    columnWidths: const {
                      0: IntrinsicColumnWidth(),
                      1: FlexColumnWidth(),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      _tableRow('Folio:', cotizacion.folioCotizacion),
                      _tableRow(
                        'Fecha Cotización: ',
                        DateFormat(
                          'dd/MM/yyyy',
                        ).format(cotizacion.fechaCotizacion),
                      ),
                      _tableRow(
                        'Vigencia:',
                        DateFormat(
                          'dd/MM/yyyy',
                        ).format(cotizacion.fechaVigencia),
                      ),
                      _tableRow('Cliente:', cotizacion.cliente),
                      _tableRow('Empresa:', cotizacion.empresa),
                      _tableRow('Teléfono:', cotizacion.telefono),
                      _tableRow('Correo:', cotizacion.correo),
                    ],
                  ),
                ]),

                _buildTitulo('Producto'),
                _buildCard([
                  Table(
                    columnWidths: const {
                      0: IntrinsicColumnWidth(),
                      1: FlexColumnWidth(),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      _tableRow('Producto: ', cotizacion.producto),
                      _tableRow('Línea: ', cotizacion.linea),
                      _tableRow('Modelo: ', cotizacion.modelo),
                      _tableRow('Color: ', cotizacion.color),
                      _tableRow('Marca Color: ', cotizacion.marcaColor),
                      _tableRow(
                        'Generación: ',
                        cotizacion.generacion.toString(),
                      ),
                      _tableRow(
                        'Número de Ejes: ',
                        cotizacion.numeroEjes.toString(),
                      ),
                      _tableRow(
                        'Unidades: ',
                        cotizacion.numeroUnidades.toString(),
                      ),
                    ],
                  ),
                ]),

                _buildTitulo('Estructura'),
                _buildCard([
                  buildEstructuraTable(
                    cotizacion.estructura.map(
                      (k, v) => MapEntry(k, v.toString()),
                    ),
                  ),
                ]),

                _buildTitulo('Adicionales de Línea'),
                ...cotizacion.adicionalesDeLinea.map(
                  (a) => _buildCard([
                    Text(
                      (a['name'] ?? a['nombre'] ?? '').toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if ((a['adicionales'] ?? '').toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 4),
                        child: Text(
                          a['adicionales'],
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Cantidad:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Text('${a['cantidad'] ?? ''}'),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Precio:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Text(
                          NumberFormat.currency(
                            locale: 'es_MX',
                            symbol: '\$',
                          ).format(
                            double.tryParse('${a['precio'] ?? a['precioUnitario'] ?? 0}') ?? 0,
                          ),
                        ),
                      ],
                    ),
                  ]),
                ),

                _buildTitulo('Adicionales Seleccionados'),
                ...cotizacion.adicionalesSeleccionados.map(
                  (a) => _buildCard([
                    Text(
                      a.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cantidad:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text('${a.cantidad}'),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Precio:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          NumberFormat.currency(
                            locale: 'es_MX',
                            symbol: '\$',
                          ).format(a.precioUnitario),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estado:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(a.estado),
                      ],
                    ),
                  ]),
                ),

                _buildTitulo('Pago y Entrega'),
                _buildCard([
                  Table(
                    columnWidths: const {
                      0: IntrinsicColumnWidth(),
                      1: FlexColumnWidth(),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      _tableRow('Forma de Pago: ', cotizacion.formaPago ?? '-'),
                      _tableRow('Método de Pago: ', cotizacion.metodoPago ?? '-'),
                      _tableRow('Moneda: ', cotizacion.moneda ?? '-'),
                      _tableRow('Cuenta: ', cotizacion.cuentaSeleccionada ?? '-'),
                      _tableRow('Otro Método: ', cotizacion.otroMetodoPago ?? '-'),
                      _tableRow('Entrega en: ', cotizacion.entregaEn ?? '-'),
                      _tableRow('Garantía: ', cotizacion.garantia ?? '-'),
                      _tableRow(
                        'Semanas de Entrega: ',
                        '${cotizacion.semanasEntrega ?? '-'} semanas',
                      ),
                    ],
                  ),
                ]),

                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      // Aquí la lógica para finalizar o guardar la cotización
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      elevation: 2,
                    ),
                    child: const Text('Finalizar Cotización'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 240, 239, 239),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.40), 
            blurRadius: 36,                        
            spreadRadius: 4,
            offset: const Offset(0, 18),          
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }


  TableRow _tableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.start,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            value,
            textAlign: TextAlign.right, // <-- Alinea a la derecha
          ),
        ),
      ],
    );
  }

  Widget buildEstructuraTable(Map<String, String> estructura) {
    return Table(
      columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
      border: TableBorder(), // <--- Sin bordes
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      children: estructuraOrden
          .where((campo) => estructura[campo['key']] != null)
          .map(
            (campo) => TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    campo['label']!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                  ).copyWith(left: 8),
                  child: Text(
                    estructura[campo['key']]!,
                    textAlign: TextAlign.justify,
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  // Orden y etiquetas de los campos de estructura
  final List<Map<String, String>> estructuraOrden = [
    {'key': 'LONGITUD', 'label': 'LONGITUD'},
    {'key': 'ANCHO', 'label': 'ANCHO'},
    {'key': 'ALTO', 'label': 'ALTO'},
    {'key': 'LONGITUD DE LANZA', 'label': 'LONGITUD DE LANZA'},
    {'key': 'ARGOLLA', 'label': 'ARGOLLA'},
    {'key': 'BISAGRAS', 'label': 'BISAGRAS'},
    {'key': 'LANZA', 'label': 'LANZA'},
    {'key': 'BASTIDOR', 'label': 'BASTIDOR'},
    {'key': 'QUINTA RUEDA', 'label': 'QUINTA RUEDA'},
    {'key': 'SUSPENSION', 'label': 'SUSPENSION'},
    {'key': 'EJES', 'label': 'EJES'},
    {'key': 'ALINEACION', 'label': 'ALINEACION'},
    {'key': 'PINTURA', 'label': 'PINTURA'},
  ];
}
