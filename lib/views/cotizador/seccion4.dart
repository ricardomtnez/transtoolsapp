import 'package:flutter/material.dart';
import 'package:transtools/models/cotizacion.dart';
import 'package:transtools/models/usuario.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class Seccion4 extends StatelessWidget {
  final Cotizacion cotizacion;
  final Usuario usuario;

  // Recibe la cotización en el constructor
  Seccion4({Key? key, required this.cotizacion, required this.usuario})
    : super(key: key);

  // Método estático para facilitar crear la ruta con argumentos
  static Route route(RouteSettings settings) {
    final args = settings.arguments as Map<String, dynamic>;
    return MaterialPageRoute(
      builder: (_) =>
          Seccion4(cotizacion: args['cotizacion'], usuario: args['usuario']),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: no_leading_underscores_for_local_identifiers
    final double _precioProductoConAdicionales =
        cotizacion.precioProductoConAdicionales ?? 0;
    // ignore: no_leading_underscores_for_local_identifiers
    final double _totalAdicionalesSeleccionados =
        cotizacion.totalAdicionales ?? 0;
    final int numeroUnidades = cotizacion.numeroUnidades.toInt();

    final precioProductoTotal = _precioProductoConAdicionales * numeroUnidades;
    final precioAdicionalesTotal =
        _totalAdicionalesSeleccionados * numeroUnidades;
    final subTotal = precioProductoTotal + precioAdicionalesTotal;
    final iva = subTotal * 0.16;
    final totalFinal = subTotal + iva;

    final int cantidadAdicionalesSeleccionados = cotizacion
        .adicionalesSeleccionados
        .fold(0, (sum, adicional) => sum + (adicional.cantidad));

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
        child: Scrollbar(
          thumbVisibility: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra amarilla pegada al AppBar
              Container(
                height: 8,
                width: double.infinity,
                color: const Color(0xFFD9D381), // Amarillo
              ),
              // Texto fijo sobre fondo azul
              Container(
                width: double.infinity,
                color: const Color(0xFF1565C0), // Azul
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: const Center(
                  child: Text(
                    'Paso 4 de 4',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              // El resto del contenido scrollable
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [                     
                       

                        _buildTitulo('Información del Vendedor'),
                        _buildCard([
                          Table(
                            columnWidths: const {
                              0: IntrinsicColumnWidth(),
                              1: FlexColumnWidth(),
                            },
                            defaultVerticalAlignment:
                                TableCellVerticalAlignment.middle,
                            children: [
                              _tableRow('Nombre del Vendedor:', usuario.fullname),
                            ],
                          ),
                        ]),

                        _buildTitulo('Datos Generales'),
                        _buildCard([
                          Table(
                            columnWidths: const {
                              0: IntrinsicColumnWidth(),
                              1: FlexColumnWidth(),
                            },
                            defaultVerticalAlignment:
                                TableCellVerticalAlignment.middle,
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
                            defaultVerticalAlignment:
                                TableCellVerticalAlignment.middle,
                            children: [
                              _tableRow('Producto: ', cotizacion.producto),
                              _tableRow('Línea: ', cotizacion.linea),
                              _tableRow('Modelo: ', cotizacion.modelo),
                              _tableRow('Número de Ejes: ', cotizacion.numeroEjes.toString()),
                              _tableRow(
                                'Precio c/u:',
                                NumberFormat.currency(
                                  locale: 'es_MX',
                                  symbol: '\$',
                                ).format(cotizacion.precioProductoConAdicionales ?? 0),
                              ),
                              _tableRow('Unidades: ', cotizacion.numeroUnidades.toString()),
                              _tableRow('Color: ', cotizacion.color),
                              _tableRow('Marca Color: ', cotizacion.marcaColor),
                              _tableRow(
                                'Generación: ',
                                cotizacion.generacion.toString(),
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
                            cotizacion.adicionalesDeLinea
                                .cast<Map<String, dynamic>>(),
                          ),
                        ]),

                        _buildTitulo('Adicionales Seleccionados'),
                        if (cotizacion.adicionalesSeleccionados.isEmpty)
                          _buildCard([
                            const Text(
                              'Sin adicionales agregados',
                              style: TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ])
                        else
                          _buildCard([
                            for (
                              int i = 0;
                              i < cotizacion.adicionalesSeleccionados.length;
                              i++
                            ) ...[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cotizacion.adicionalesSeleccionados[i].nombre,
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
                                      Text(
                                        '${cotizacion.adicionalesSeleccionados[i].cantidad}',
                                      ),
                                    ],
                                  ),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Precio c/u:',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        NumberFormat.currency(
                                          locale: 'es_MX',
                                          symbol: '\$',
                                        ).format(
                                          cotizacion
                                              .adicionalesSeleccionados[i]
                                              .precioUnitario,
                                        ),
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
                                      Text(
                                        cotizacion.adicionalesSeleccionados[i].estado,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (i != cotizacion.adicionalesSeleccionados.length - 1)
                                const Divider(height: 32, thickness: 1),
                            ],
                          ]),

                        _buildTitulo('Pago y Entrega'),
                        _buildCard([
                          Table(
                            columnWidths: const {
                              0: IntrinsicColumnWidth(),
                              1: FlexColumnWidth(),
                            },
                            defaultVerticalAlignment:
                                TableCellVerticalAlignment.middle,
                            children: [
                              _tableRow(
                                'Forma de Pago: ',
                                cotizacion.formaPago ?? '-',
                              ),
                              _tableRow(
                                'Método de Pago: ',
                                cotizacion.metodoPago ?? '-',
                              ),
                              _tableRow('Moneda: ', cotizacion.moneda ?? '-'),
                              _tableRow(
                                'Cuenta: ',
                                cotizacion.cuentaSeleccionada ?? '-',
                              ),
                              _tableRow('Entrega en: ', cotizacion.entregaEn ?? '-'),
                              _tableRow(
                                'Anticipo: ',
                                cotizacion.anticipoSeleccionado != null &&
                                        cotizacion.anticipoSeleccionado!.isNotEmpty
                                    ? '${cotizacion.anticipoSeleccionado}%'
                                    : '-',
                              ),
                              _tableRow(
                                'Semanas de Entrega: ',
                                '${cotizacion.semanasEntrega ?? '-'} semanas',
                              ),
                            ],
                          ),
                        ]),

                        _buildTitulo('Resumen de Pago'),
                        _buildCard([
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${cotizacion.producto} (${cotizacion.numeroUnidades}):',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Tooltip(
                                message: 'Este es el precio total para ${cotizacion.numeroUnidades} unidades',
                                child: Text(
                                  NumberFormat.currency(
                                    locale: 'es_MX',
                                    symbol: '\$',
                                  ).format(
                                    (cotizacion.precioProductoConAdicionales ?? 0) *
                                        (cotizacion.numeroUnidades),
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF1565C0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                // ignore: unnecessary_brace_in_string_interps
                                'Adicionales (${cantidadAdicionalesSeleccionados}):',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                              Tooltip(
                                message: 'Este es el precio total de los adicionales para ${cotizacion.numeroUnidades} unidades',
                                child: Text(
                                  NumberFormat.currency(
                                    locale: 'es_MX',
                                    symbol: '\$',
                                  ).format(
                                    (cotizacion.totalAdicionales ?? 0) * (cotizacion.numeroUnidades),
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF1565C0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Subtotal:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                NumberFormat.currency(
                                  locale: 'es_MX',
                                  symbol: '\$',
                                ).format(subTotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF1565C0),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'IVA (16%):',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                NumberFormat.currency(
                                  locale: 'es_MX',
                                  symbol: '\$',
                                ).format(iva),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF1565C0),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(thickness: 1, color: Colors.black26),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                NumberFormat.currency(
                                  locale: 'es_MX',
                                  symbol: '\$',
                                ).format(totalFinal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF1565C0),
                                ),
                              ),
                            ],
                          ),
                        ]),

                        const SizedBox(height: 24),
                        Center(
                          child: ElevatedButton(
                            onPressed: () async {
                              final pdf = pw.Document();

                              pdf.addPage(
                                pw.Page(
                                  build: (pw.Context context) {
                                    return pw.Column(
                                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.Text(
                                          'Resumen de Cotización',
                                          style: pw.TextStyle(
                                            fontSize: 24,
                                            fontWeight: pw.FontWeight.bold,
                                          ),
                                        ),
                                        pw.SizedBox(height: 16),
                                        pw.Text(
                                          'Folio: ${cotizacion.folioCotizacion}',
                                        ),
                                        pw.Text('Cliente: ${cotizacion.cliente}'),
                                        pw.Text('Producto: ${cotizacion.producto}'),
                                        pw.Text(
                                          'Unidades: ${cotizacion.numeroUnidades}',
                                        ),
                                        pw.SizedBox(height: 16),
                                        pw.Text(
                                          'Precio del producto: \$${cotizacion.precioProductoConAdicionales?.toStringAsFixed(2) ?? "0.00"}',
                                        ),
                                        pw.Text(
                                          'Precio de adicionales: \$${cotizacion.totalAdicionales?.toStringAsFixed(2) ?? "0.00"}',
                                        ),
                                        pw.Text(
                                          'Sub total: \$${subTotal.toStringAsFixed(2)}',
                                        ),
                                        pw.Text(
                                          'IVA (16%): \$${iva.toStringAsFixed(2)}',
                                        ),
                                        pw.Text(
                                          'Total Final: \$${totalFinal.toStringAsFixed(2)}',
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              );

                              // Mostrar diálogo para imprimir o guardar
                              await Printing.layoutPdf(
                                onLayout: (PdfPageFormat format) async => pdf.save(),
                              );
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
            ],
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
        crossAxisAlignment: CrossAxisAlignment.center, 
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
            textAlign: TextAlign.center, // Etiqueta centrada
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            value,
            textAlign: TextAlign.right, 
          ),
        ),
      ],
    );
  }

  Widget buildEstructuraTable(
    Map<String, String> estructura,
    List<Map<String, dynamic>> adicionalesDeLinea,
  ) {
    final rows = estructura.entries.map(
      (entry) => TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              entry.key,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8).copyWith(left: 8),
            child: Text(
              entry.value,
              textAlign: TextAlign.justify,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    ).toList();

    // Agrega el título solo si hay adicionales de línea no excluidos
    final adicionalesIncluidos = cotizacion.adicionalesDeLinea
        .where((a) => a['excluido'] != true)
        .toList();

    if (cotizacion.adicionalesDeLinea.isNotEmpty && adicionalesIncluidos.isEmpty) {
      rows.add(
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Sin adicional de línea',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            const SizedBox(),
          ],
        ),
      );
    }

    if (adicionalesIncluidos.isNotEmpty) {
      rows.add(
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Adicionales de Línea',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            const SizedBox(),
          ],
        ),
      );

      for (final a in adicionalesIncluidos) {
        rows.add(
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  (a['name'] ?? a['nombre'] ?? '').toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.left,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                ).copyWith(left: 8),
                child: Text(
                  '${a['adicionales'] ?? ''}',
                  textAlign: TextAlign.justify,
                  style: const TextStyle(
                    fontSize: 14, // <-- Cambiado a 14
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }

    return Table(
      columnWidths: const {0: FixedColumnWidth(140), 1: FlexColumnWidth()},
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      children: rows,
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