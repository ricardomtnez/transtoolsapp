import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:transtools/api/quote_controller.dart';
import 'package:transtools/models/cotizacion.dart';
import 'package:transtools/models/usuario.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
// printing import removed from this file (not used here)

class Seccion5 extends StatelessWidget {
  final Cotizacion cotizacion;
  final Usuario usuario;

  // Recibe la cotización en el constructor
  Seccion5({Key? key, required this.cotizacion, required this.usuario})
    : super(key: key);

  // Método estático para facilitar crear la ruta con argumentos
  static Route route(RouteSettings settings) {
    final args = settings.arguments as Map<String, dynamic>;
    return MaterialPageRoute(
      builder: (_) =>
          Seccion5(cotizacion: args['cotizacion'], usuario: args['usuario']),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: no_leading_underscores_for_local_identifiers
    final double precioProductoConAdicionales =
        cotizacion.precioProductoConAdicionales ?? 0;
    // ignore: no_leading_underscores_for_local_identifiers
    final double totalAdicionalesSeleccionados =
        cotizacion.totalAdicionales ?? 0;
    final int numeroUnidades = cotizacion.numeroUnidades.toInt();

  final double proteccionPorUnidad = cotizacion.proteccionMonto ?? 0.0;
  final double proteccionTotal = proteccionPorUnidad * numeroUnidades;
  final double displayUnitPrice = precioProductoConAdicionales + proteccionPorUnidad;
  final precioProductoTotal = displayUnitPrice * numeroUnidades;
    final precioAdicionalesTotal =
        totalAdicionalesSeleccionados * numeroUnidades;
  final double costoEntrega = cotizacion.costoEntrega ?? 0;
  final double costoEntregaTotal = costoEntrega * numeroUnidades;
  // precioProductoTotal ya incluye la protección (se cargó en displayUnitPrice)
  final subTotal = precioProductoTotal + precioAdicionalesTotal + costoEntregaTotal;
    // Apply discount (if any) before IVA. The stored discount is per unit,
    // so multiply by the number of units to get the total discount amount.
    final double descuentoPorUnidad = cotizacion.descuento ?? 0.0;
    final double descuentoTotal = descuentoPorUnidad * numeroUnidades;
    final double subTotalConDescuento = (subTotal - descuentoTotal).clamp(0.0, double.infinity);
      final iva = subTotalConDescuento * 0.16;
      final totalFinal = subTotalConDescuento + iva;

  final int cantidadAdicionalesSeleccionados = cotizacion
    .adicionalesSeleccionados
    .fold(0, (sum, adicional) => sum + (adicional.cantidad));

    return Scaffold(
  backgroundColor: const Color(0xFFb5191f),
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
                color: const Color(0xFFb5191f), // Kenworth rojo
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
                              _tableRow(
                                'Nombre del Vendedor:',
                                usuario.fullname,
                              ),
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
                              _tableRow(
                                'Número de Ejes: ',
                                cotizacion.numeroEjes.toString(),
                              ),
                              _tableRow(
                                'Precio c/u:',
                                NumberFormat.currency(
                                  locale: 'es_MX',
                                  symbol: '\$',
                                ).format(
                                  cotizacion.precioProductoConAdicionales ?? 0,
                                ),
                              ),
                              // Mostrar protección debajo del precio por unidad si aplica
                              if (proteccionPorUnidad > 0)
                                TableRow(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      child: Text(
                                        'Protección:',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            NumberFormat.currency(
                                              locale: 'es_MX',
                                              symbol: '\$',
                                            ).format(proteccionPorUnidad),
                                            textAlign: TextAlign.right,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Precio modificado: incluye protección por unidad',
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              // Mostrar el precio unitario modificado (precio + protección) si aplica
                              if (proteccionPorUnidad > 0)
                                TableRow(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      child: Text(
                                        'Precio modificado c/u:',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      child: Text(
                                        NumberFormat.currency(
                                          locale: 'es_MX',
                                          symbol: '\$',
                                        ).format((cotizacion.precioProductoConAdicionales ?? 0) + proteccionPorUnidad),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              _tableRow(
                                'Unidades: ',
                                cotizacion.numeroUnidades.toString(),
                              ),
                              _tableRow('Color: ', cotizacion.color),
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

                        _buildTitulo('Equipamiento Seleccionados'),
                        if (cotizacion.adicionalesSeleccionados.isEmpty)
                          _buildCard([
                            const Text(
                              'Sin equipamiento agregado',
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
                                    cotizacion
                                        .adicionalesSeleccionados[i]
                                        .nombre,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Cantidad:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${cotizacion.adicionalesSeleccionados[i].cantidad}',
                                      ),
                                    ],
                                  ),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Precio c/u:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Estado:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        cotizacion
                                            .adicionalesSeleccionados[i]
                                            .estado,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (i !=
                                  cotizacion.adicionalesSeleccionados.length -
                                      1)
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
                              _tableRow(
                                'Entrega en: ',
                                cotizacion.entregaEn ?? '-',
                              ),
                              _tableRow(
                                'Anticipo: ',
                                cotizacion.anticipoSeleccionado != null &&
                                        cotizacion
                                            .anticipoSeleccionado!
                                            .isNotEmpty
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
                                message:
                                    'Este es el precio total para ${cotizacion.numeroUnidades} unidades',
                                child: Text(
                                  NumberFormat.currency(
                                    locale: 'es_MX',
                                    symbol: '\$',
                                  ).format(
                                    (precioProductoConAdicionales) * (cotizacion.numeroUnidades),
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFFb5191f),
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
                                'Equipamientos (${cantidadAdicionalesSeleccionados}):',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                              Tooltip(
                                message:
                                    'Este es el precio total de los adicionales para ${cotizacion.numeroUnidades} unidades',
                                child: Text(
                                  NumberFormat.currency(
                                    locale: 'es_MX',
                                    symbol: '\$',
                                  ).format(
                                    (cotizacion.totalAdicionales ?? 0) *
                                        (cotizacion.numeroUnidades),
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFFb5191f),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Flete de envio:',
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
                                ).format(costoEntregaTotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFFb5191f),
                                ),
                              ),
                            ],
                          ),
                          // Mostrar protección (si aplica) en la pantalla para usuarios internos
                          if (proteccionTotal > 0) ...[
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Protección:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      NumberFormat.currency(
                                        locale: 'es_MX',
                                        symbol: '\$',
                                      ).format(proteccionTotal),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFFb5191f),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '( ${NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(proteccionPorUnidad)} c/u )',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
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
                                  color: Color(0xFFb5191f),
                                ),
                              ),
                            ],
                          ),
                          if (descuentoTotal > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Descuento:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      NumberFormat.currency(
                                        locale: 'es_MX',
                                        symbol: '\$',
                                      ).format(descuentoTotal),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFFb5191f),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '( ${NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(descuentoPorUnidad)} c/u )',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                          if (descuentoTotal > 0) ...[
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Subtotal desc:',
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
                                  ).format(subTotalConDescuento),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFFb5191f),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
                                  color: Color(0xFFb5191f),
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
                                  color: Color(0xFFb5191f),
                                ),
                              ),
                            ],
                          ),
                        ]),

                        const SizedBox(height: 24),
                        Center(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: () async {
                                    await finalizarCotizacionEnMonday(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 12,
                                    ), // Menor padding
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15, // Menor tamaño de fuente
                                    ),
                                    elevation: 2,
                                  ),
                                  child: const Text('Guardar Cotización'),
                                ),
                                // 'Imprimir' button removed per request
                              ],
                            ),
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

  Future<Uint8List> _generarPDF(BuildContext context) async {
    try {
      final pdf = pw.Document();

      // Carga los logos ANTES de cualquier await que dependa de context
      final logoBytes = await DefaultAssetBundle.of(context).load('assets/transtools_logo.png');
    // logo Kenworth (puede contener tambien DAF en el mismo asset)
    Uint8List kenBytesList;
    try {
      // ignore: use_build_context_synchronously
      final kenBytes = await DefaultAssetBundle.of(context).load('assets/Kenworth-logo.png');
      kenBytesList = kenBytes.buffer.asUint8List();
    } catch (_) {
      // fallback al logo principal si no existe Kenworth
      kenBytesList = logoBytes.buffer.asUint8List();
    }
  // no usamos logo10 porque el footer fue eliminado
    final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());
    final logoKen = pw.MemoryImage(kenBytesList);

  // Calcular totales para el PDF
    final double precioProductoConAdicionales =
        cotizacion.precioProductoConAdicionales ?? 0;
    final int numeroUnidades = cotizacion.numeroUnidades.toInt();

  final double costoEntregaPdf = cotizacion.costoEntrega ?? 0;
  final double costoEntregaTotalPdf = costoEntregaPdf * numeroUnidades;
    // Suma de adicionales calculada directamente desde la lista (por unidad)
    final double sumAdicionalesUnit = cotizacion.adicionalesSeleccionados
        .fold(0.0, (double s, a) => s + (a.precioUnitario * a.cantidad));
    final double sumAdicionalesTotal = sumAdicionalesUnit * numeroUnidades;

    final double proteccionUnitPdf = cotizacion.proteccionMonto ?? 0.0;
    final double displayUnitPricePdf = precioProductoConAdicionales + proteccionUnitPdf;

    final double subTotal =
      (displayUnitPricePdf * numeroUnidades) +
      sumAdicionalesTotal +
      costoEntregaTotalPdf;
  // Aplicar descuento: la cotizacion.descuento viene por unidad, multiplicar por unidades
  final double descuentoUnitPdf = cotizacion.descuento ?? 0.0;
  final double descuentoPdf = descuentoUnitPdf * numeroUnidades;
  final double subTotalConDescuentoPdf = (subTotal - descuentoPdf).clamp(0.0, double.infinity);
    final double iva = subTotalConDescuentoPdf * 0.16;
    final double totalFinal = subTotalConDescuentoPdf + iva;

    // Valores seguros para evitar Null check operator used on a null value
  final String folioSafe = cotizacion.folioCotizacion;
  String fechaCotSafe = '-';
  int diasVigencia = 0;
    try {
      fechaCotSafe = DateFormat('dd/MM/yyyy').format(cotizacion.fechaCotizacion);
    } catch (_) {
      fechaCotSafe = '-';
    }
    try {
      fechaCotSafe = DateFormat('dd/MM/yyyy').format(cotizacion.fechaCotizacion);
    } catch (_) {
      fechaCotSafe = '-';
    }
    try {
      diasVigencia = cotizacion.fechaVigencia.difference(cotizacion.fechaCotizacion).inDays;
    } catch (_) {
      diasVigencia = 0;
    }

    // Si la entrega fue seleccionada en Planta Titanium (El Carmen Tequexquitla)
    // no debemos imprimir la línea "Entrega en" en el PDF.
  final bool hideEntregaPlanta = (cotizacion.entregaEn != null && cotizacion.entregaEn!.trim() == 'Planta Titanium (El Carmen Tequexquitla)');

  // cantidadAdicionalesSeleccionados no se necesita en el PDF (se muestra numeroUnidades en el resumen)

      pdf.addPage(
        pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: pw.EdgeInsets.zero,
        header: (pw.Context context) {
          // Tarjeta blanca redondeada que contiene logos y bloque de cotización
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Logo izquierdo
                  pw.Container(
                    width: 260,
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Image(logo, height: 58, fit: pw.BoxFit.contain),
                  ),

                  pw.Spacer(),

                  // Bloque derecho: logo Kenworth arriba, título y datos a la derecha
                  pw.Container(
                    width: 260,
                    alignment: pw.Alignment.centerRight,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Image(logoKen, height: 36, fit: pw.BoxFit.contain),
                        pw.SizedBox(height: 6),
                        // Mostrar número de página usando el contexto del header (pagesCount será correcto aquí)
                        pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', style: pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        
        build: (pw.Context context) => [
          
          // Datos del cliente
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 12),
                // Dos columnas: izquierda = datos del cliente, derecha = datos de cotización
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Izquierda: datos del cliente
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.RichText(
                            text: pw.TextSpan(
                              children: [
                                pw.TextSpan(
                                  text: 'ATENCIÓN: ',
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                pw.TextSpan(
                                  text: cotizacion.cliente,
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.RichText(
                            text: pw.TextSpan(
                              children: [
                                pw.TextSpan(
                                  text: 'EMPRESA: ',
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                pw.TextSpan(
                                  text: cotizacion.empresa,
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.RichText(
                            text: pw.TextSpan(
                              children: [
                                pw.TextSpan(
                                  text: 'CORREO: ',
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                                pw.TextSpan(
                                  text: cotizacion.correo,
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.normal,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.RichText(
                            text: pw.TextSpan(
                              children: [
                                pw.TextSpan(
                                  text: 'TELÉFONO: ',
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                                pw.TextSpan(
                                  text: cotizacion.telefono,
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.normal,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Derecha: bloque de cotización (Página, No., Fecha)
                    pw.Expanded(
                        flex: 1,
                        child: pw.Container(
                          alignment: pw.Alignment.topRight,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text('COTIZACIÓN', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                              pw.SizedBox(height: 6),
                              // El número de página con total se muestra ahora en el footer
                              pw.SizedBox(height: 0),
                              pw.SizedBox(height: 6),
                              pw.Text('No. de Cotización: $folioSafe', style: pw.TextStyle(fontSize: 10)),
                              pw.SizedBox(height: 6),
                              pw.Text('Fecha de Cotización: $fechaCotSafe', style: pw.TextStyle(fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Center(
                  child: pw.Text(
                    '${cotizacion.producto.toUpperCase()} ${cotizacion.linea}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'MODELO:',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          pw.Text(
                            cotizacion.modelo,
                            style: pw.TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'EJES:',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          pw.Text(
                            '${cotizacion.numeroEjes}',
                            style: pw.TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'GENERACION:',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          pw.Text(
                            '${cotizacion.generacion}',
                            style: pw.TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'COLOR:',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          pw.Text(
                            cotizacion.color,
                            style: pw.TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          // Sección estructura específica
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 24),
            child: pw.Container(
              color: PdfColor.fromInt(0xFFb5191f),
              padding: const pw.EdgeInsets.symmetric(vertical: 6),
              child: pw.Center(
                child: pw.Text(
                  'ESTRUCTURA ESPECÍFICA',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: pw.Table(
              columnWidths: const {
                0: pw.FixedColumnWidth(140),
                1: pw.FlexColumnWidth(220),
              },
              children: [
                // Estructura en ORDEN ORIGINAL (inserción del mapa), filtrando excluidos
                for (final entry in cotizacion.estructura.entries)
                  if (!(cotizacion.excludedFeatures?['Estructura'] ?? <String>{}).contains(entry.key))
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 6),
                          child: pw.Text(
                            entry.key,
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 6),
                          child: pw.Text(
                            entry.value,
                            style: pw.TextStyle(fontSize: 11),
                            textAlign: pw.TextAlign.justify,
                          ),
                        ),
                      ],
                    ),
                // Título de adicionales de línea (solo si hay)
                if (cotizacion.adicionalesDeLinea.any(
                  (a) => a['excluido'] != true,
                ))
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 8),
                        child: pw.Text(
                          'Adicionales de Línea',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      pw.SizedBox(),
                    ],
                  ),
                // Adicionales de línea como filas FILTRANDO EXCLUIDOS
                for (final adicional in cotizacion.adicionalesDeLinea)
                  if (adicional['excluido'] != true)
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 6),
                          child: pw.Text(
                            (adicional['nombre'] ?? adicional['name'] ?? '')
                                .toString(),
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            vertical: 6,
                          ).copyWith(left: 8),
                          child: pw.Text(
                            adicional['adicionales']?.toString() ?? '',
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
              ],
            ),
          ),
          if (cotizacion.adicionalesSeleccionados.isNotEmpty) ...[
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 8,
              ),
              child: pw.Table(
                columnWidths: const {
                  0: pw.FixedColumnWidth(160),
                  1: pw.FixedColumnWidth(60),
                  2: pw.FixedColumnWidth(80),
                  3: pw.FixedColumnWidth(80),
                },
                border: pw.TableBorder(
                  horizontalInside: pw.BorderSide(
                    width: 0.5,
                    color: PdfColor.fromInt(0xFFb5191f),
                  ),
                ),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFb5191f),
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'EQUIPAMIENTO PERSONALIZADO',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            'CANTIDAD',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'PRECIO UNITARIO',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            'TOTAL',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  for (final adicional in cotizacion.adicionalesSeleccionados)
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            adicional.nombre,
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            '${adicional.cantidad}',
                            style: pw.TextStyle(fontSize: 11),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            NumberFormat.currency(
                              locale: 'es_MX',
                              symbol: '\$',
                            ).format(adicional.precioUnitario),
                            style: pw.TextStyle(fontSize: 11),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            NumberFormat.currency(
                              locale: 'es_MX',
                              symbol: '\$',
                            ).format(
                              adicional.precioUnitario * adicional.cantidad,
                            ),
                            style: pw.TextStyle(fontSize: 11),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  // Resumen: total de adicionales (por unidad y total general)
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(top: pw.BorderSide(width: 0.8, color: PdfColors.grey300)),
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'TOTAL EQUIPAMIENTOS',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            '$numeroUnidades',
                            style: pw.TextStyle(fontSize: 11),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(sumAdicionalesUnit),
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(sumAdicionalesTotal),
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          // Tabla de totales
          // No forzar salto de página: dejar que el contenido (equipamiento + resumen)
          // fluya y quede en la misma hoja si cabe. Añadimos un espaciamiento pequeño.
          pw.SizedBox(height: 12),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: pw.Table(
              columnWidths: const {
                0: pw.FixedColumnWidth(160),
                1: pw.FixedColumnWidth(60),
                2: pw.FixedColumnWidth(80),
                3: pw.FixedColumnWidth(80),
              },
              border: pw.TableBorder(
                horizontalInside: pw.BorderSide(
                  width: 0.5,
                  color: PdfColor.fromInt(0xFFb5191f),
                ),
              ),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFb5191f)),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'RESUMEN DE COMPRA',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Container(
                        alignment:
                            pw.Alignment.center, // Centra el texto en la celda
                        child: pw.Text(
                          'CANTIDAD',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'PRECIO UNITARIO',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Container(
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          'IMPORTE',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        cotizacion.producto,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        '${cotizacion.numeroUnidades}',
                        style: pw.TextStyle(fontSize: 11),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        NumberFormat.currency(
                          locale: 'es_MX',
                          symbol: '\$',
                        ).format(displayUnitPricePdf),
                        style: pw.TextStyle(fontSize: 11),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        NumberFormat.currency(
                          locale: 'es_MX',
                          symbol: '\$',
                        ).format(
                          (displayUnitPricePdf) * (cotizacion.numeroUnidades),
                        ),
                        style: pw.TextStyle(fontSize: 11),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                ),
                if (cotizacion.adicionalesSeleccionados.isNotEmpty)
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'EQUIPAMIENTO PERSONALIZADO',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            '$numeroUnidades', // Mostrar número de unidades aquí
                            style: pw.TextStyle(fontSize: 11),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            NumberFormat.currency(
                              locale: 'es_MX',
                              symbol: '\$',
                            ).format(cotizacion.totalAdicionales ?? 0),
                            style: pw.TextStyle(fontSize: 11),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            NumberFormat.currency(
                              locale: 'es_MX',
                              symbol: '\$',
                            ).format(
                              (cotizacion.totalAdicionales ?? 0) *
                                  (cotizacion.numeroUnidades),
                            ),
                            style: pw.TextStyle(fontSize: 11),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                // Fila para Costo de entrega como ítem (cantidad = unidades)
                if (!hideEntregaPlanta)
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'FLETE DE ENVÍO',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          // ignore: unnecessary_brace_in_string_interps
                          '${numeroUnidades}',
                          style: pw.TextStyle(fontSize: 11),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          NumberFormat.currency(
                            locale: 'es_MX',
                            symbol: '\$',
                          ).format(cotizacion.costoEntrega ?? 0),
                          style: pw.TextStyle(fontSize: 11),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          NumberFormat.currency(
                            locale: 'es_MX',
                            symbol: '\$',
                          ).format((cotizacion.costoEntrega ?? 0) * numeroUnidades),
                          style: pw.TextStyle(fontSize: 11),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                // PROTECCIÓN: cargo interno por unidad — no se imprime en la cotización al cliente
              ],
            ),
          ),

          // Totales (envuelto en LayoutBuilder para evitar que la tabla se divida)
          pw.LayoutBuilder(builder: (ctxLayout, constraints) {
            // Estimación conservadora (aumentada) de la altura que ocupará la tabla de totales
            // Incrementamos para cubrir cualquier padding extra y el bloque 'TOTAL' grande
            // Estimate rows dynamically: SUBTOTAL, optional DESCUENTO, optional S/DESC, IVA, TOTAL + margin
            int estimatedRows = 5; // SUBTOTAL, IVA, TOTAL + margins
            if (descuentoPdf > 0) {
              // DESCUENTO and S/DESC rows will be present
              estimatedRows = 7;
            }
            const double rowHeight = 36.0; // altura estimada por fila (más conservadora)
            const double extraPadding = 40.0; // padding interno y márgenes
            final estimatedTableHeight = estimatedRows * rowHeight + extraPadding;

            // Definimos el widget de la tabla exactamente como antes (sin cambios estructurales)
            final totalsTable = pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: pw.Table(
                columnWidths: const {
                  0: pw.FixedColumnWidth(160),
                  1: pw.FixedColumnWidth(60),
                  2: pw.FixedColumnWidth(80),
                  3: pw.FixedColumnWidth(80),
                },
                border: null, // Sin bordes
                children: [
                  // Mostrar Subtotal original
                  pw.TableRow(
                    children: [
                      pw.Container(), // Columna 1 en blanco
                      pw.Container(), // Columna 2 en blanco
                      pw.Container(
                        color: PdfColor.fromInt(0xFFb5191f),
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'SUBTOTAL',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                            color: PdfColors.white,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Container(
                        color: PdfColor.fromInt(0xFFb5191f),
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          NumberFormat.currency(
                            locale: 'es_MX',
                            symbol: '\$',
                          ).format(subTotal),
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                            color: PdfColors.white,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  // Descuento (si aplica)
                  if (descuentoPdf > 0)
                    pw.TableRow(
                      children: [
                        pw.Container(),
                        pw.Container(),
                        pw.Container(
                          color: PdfColor.fromInt(0xFFb5191f),
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'DESCUENTO',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                              color: PdfColors.white,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Container(
                          color: PdfColor.fromInt(0xFFb5191f),
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            NumberFormat.currency(
                              locale: 'es_MX',
                              symbol: '\$',
                            ).format(descuentoPdf),
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                              color: PdfColors.white,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  // Subtotal luego del descuento (solo si hubo descuento)
                  if (descuentoPdf > 0)
                    pw.TableRow(
                      children: [
                        pw.Container(),
                        pw.Container(),
                        pw.Container(
                          color: PdfColor.fromInt(0xFFb5191f),
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'S/DESC.',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                              color: PdfColors.white,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Container(
                          color: PdfColor.fromInt(0xFFb5191f),
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            NumberFormat.currency(
                              locale: 'es_MX',
                              symbol: '\$',
                            ).format(subTotalConDescuentoPdf),
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                              color: PdfColors.white,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  pw.TableRow(
                    children: [
                      pw.Container(),
                      pw.Container(),
                      pw.Container(
                        color: PdfColor.fromInt(0xFFb5191f),
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'IVA',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                            color: PdfColors.white,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Container(
                        color: PdfColor.fromInt(0xFFb5191f),
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          NumberFormat.currency(
                            locale: 'es_MX',
                            symbol: '\$',
                          ).format(iva),
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                            color: PdfColors.white,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  // COSTO ENTREGA ya se incluye en el detalle como fila con cantidad y importe
                  pw.TableRow(
                    children: [
                      pw.Container(),
                      pw.Container(),
                      pw.Container(
                        color: PdfColor.fromInt(0xFFb5191f),
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'TOTAL',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                            color: PdfColors.white,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Container(
                        color: PdfColor.fromInt(0xFFb5191f),
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          NumberFormat.currency(
                            locale: 'es_MX',
                            symbol: '\$',
                          ).format(totalFinal),
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                            color: PdfColors.white,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );

            // Si no hay suficiente espacio en la página actual, movemos la tabla entera a la siguiente
            final available = (constraints?.maxHeight) ?? 0.0;
            if (available < estimatedTableHeight) {
              // No hay espacio suficiente: rellenamos con un spacer mayor que
              // el espacio disponible para forzar que el `totalsTable` se coloque
              // en la siguiente página. Evita depender de pw.PageBreak().
              return pw.Column(children: [pw.SizedBox(height: available + estimatedTableHeight), totalsTable]);
            }

            return totalsTable;
          }),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: pw.Column(
              children: [
                pw.SizedBox(height: 10),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.ConstrainedBox(
                        constraints: const pw.BoxConstraints(minHeight: 120),
                        child: pw.Container(
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                              color: PdfColor.fromInt(0xFFb5191f),
                              width: 1,
                            ),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Container(
                                color: PdfColor.fromInt(0xFFb5191f),
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text(
                                  'CONDICIONES DE PAGO',
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text(
                                  'Forma de pago: ${cotizacion.anticipoSeleccionado}% de anticipo, y ${100 - (int.tryParse(cotizacion.anticipoSeleccionado ?? '0') ?? 0)}% contra entrega.',
                                  style: pw.TextStyle(fontSize: 11),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text(
                                  cotizacion.cuentaSeleccionada ?? '-',
                                  style: pw.TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.ConstrainedBox(
                        constraints: const pw.BoxConstraints(minHeight: 120),
                        child: pw.Container(
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                              color: PdfColor.fromInt(0xFFb5191f),
                              width: 1,
                            ),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Container(
                                color: PdfColor.fromInt(0xFFb5191f),
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text(
                                  'TIEMPO DE ENTREGA',
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text(
                                  'Un aproximado de ${cotizacion.semanasEntrega} semanas',
                                  style: pw.TextStyle(fontSize: 11),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text(
                                  'Entrega en: ${cotizacion.entregaEn}',
                                  style: pw.TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Nota y pie de página
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: pw.Text(
              '*Nota: Esta cotización tiene una vigencia de $diasVigencia días a partir del $fechaCotSafe. Después de ese periodo, necesita solicitar una nueva cotización.',
              style: pw.TextStyle(fontSize: 9),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('Atentamente,', style: pw.TextStyle(fontSize: 11)),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.SizedBox(height: 15),
                      pw.Text(
                        usuario.fullname,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                      pw.Text(
                        'Gerente de Ventas de Equipo Aliado',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                      pw.Text(
                        'ventas@transtools.com.mx',
                        style: pw.TextStyle(fontSize: 11),
                        textAlign: pw.TextAlign.right,
                      ),
                      pw.Text(
                        '735 206 5016',
                        style: pw.TextStyle(fontSize: 11),
                        textAlign: pw.TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ], //
      ),
      ); //

      return await pdf.save();
    } catch (e, st) {
      // Si algo falla, genera un PDF con el error para que el usuario lo vea en preview
      final errPdf = pw.Document();
      errPdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.letter,
          build: (pw.Context c) => pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Error generando PDF:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 12),
                pw.Text(e.toString(), style: pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 12),
                pw.Text('Stack trace (truncado):', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Text(st.toString().split('\n').take(6).join('\n'), style: pw.TextStyle(fontSize: 9)),
              ],
            ),
          ),
        ),
      );
      return await errPdf.save();
    }
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
          child: Text(value, textAlign: TextAlign.right),
        ),
      ],
    );
  }

  Widget buildEstructuraTable(
    Map<String, String> estructura,
    List<Map<String, dynamic>> adicionalesDeLinea,
  ) {
    // Obtén los excluidos desde cotizacion
    final excludedKeys =
        cotizacion.excludedFeatures?['Estructura'] ?? <String>{};

    final rows = estructura.entries
        .where(
          (entry) => !excludedKeys.contains(entry.key),
        ) // <-- FILTRA EXCLUIDOS
        .map(
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
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                ).copyWith(left: 8),
                child: Text(
                  entry.value,
                  textAlign: TextAlign.justify,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        )
        .toList();

    // Agrega el título solo si hay adicionales de línea no excluidos
    final adicionalesIncluidos = cotizacion.adicionalesDeLinea
        .where((a) => a['excluido'] != true)
        .toList();

    if (cotizacion.adicionalesDeLinea.isNotEmpty &&
        adicionalesIncluidos.isEmpty) {
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
                  style: const TextStyle(fontSize: 14),
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

  // Orden y etiquetas de los campos de estructura de la seccion
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

  //metodo con pasos:
  //Método que nos permite finalizar la cotización
  Future<void> finalizarCotizacionEnMonday(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_upload, size: 48, color: Color(0xFFb5191f)),
              const SizedBox(height: 16),
              const Text(
                'Subiendo cotización...',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              CircularProgressIndicator(color: Color(0xFFb5191f)),
            ],
          ),
        ),
      ),
    );

    try {
      final Uint8List pdfBytes = await _generarPDF(context);
      final String mesActual = DateTime.now().month.toString().padLeft(2, '0');
      final int itemId = await QuoteController.crearItemCotizacion(
        cotizacion,
        usuario,
        mesActual,
      );
      await QuoteController.subirArchivoCotizacionPdf(
        itemId,
        pdfBytes,
        cotizacion,
      );
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Cierra el loader

      // Diálogo de éxito
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 48, color: Colors.green[600]),
                const SizedBox(height: 16),
                const Text(
                  'Cotización realizada con éxito',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'La cotización se subió correctamente a Monday.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFb5191f),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/dashboard',
                        (Route<dynamic> route) => false,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Cierra el loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ocurrió un error al subir la cotización.')),
      );
    }
  }
}