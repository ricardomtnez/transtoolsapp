import 'package:flutter/material.dart';
import 'package:transtools/models/cotizacion.dart';

class Seccion4 extends StatelessWidget {
  final Cotizacion cotizacion;

  // Recibe la cotización en el constructor
  const Seccion4({Key? key, required this.cotizacion}) : super(key: key);

  // Método estático para facilitar crear la ruta con argumentos
  static Route route(RouteSettings settings) {
    final args = settings.arguments as Map<String, dynamic>;
    return MaterialPageRoute(
      builder: (_) => Seccion4(
        cotizacion: args['cotizacion'],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ya tienes cotizacion en la propiedad, no necesitas extraerla del ModalRoute

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
                  _item('Folio:', cotizacion.folioCotizacion),
                  _item('Fecha Cotización:', cotizacion.fechaCotizacion.toIso8601String()),
                  _item('Vigencia:', cotizacion.fechaVigencia.toIso8601String()),
                  _item('Cliente:', cotizacion.cliente),
                  _item('Empresa:', cotizacion.empresa),
                  _item('Teléfono:', cotizacion.telefono),
                  _item('Correo:', cotizacion.correo),
                ]),

                _buildTitulo('Producto'),
                _buildCard([
                  _item('Producto:', cotizacion.producto),
                  _item('Línea:', cotizacion.linea),
                  _item('Modelo:', cotizacion.modelo),
                  _item('Color:', cotizacion.color),
                  _item('Marca Color:', cotizacion.marcaColor),
                  _item('Generación:', cotizacion.generacion.toString()),
                  _item('Número de Ejes:', cotizacion.numeroEjes.toString()),
                  _item('Unidades:', cotizacion.numeroUnidades.toString()),
                ]),

                _buildTitulo('Estructura'),
                _buildCard(
                  cotizacion.estructura.entries
                      .map((e) => _item(e.key, e.value.toString()))
                      .toList(),
                ),

                _buildTitulo('Adicionales de Línea'),
                _buildCard(
                  cotizacion.adicionalesDeLinea
                      .map((a) => _item('•', a.toString()))
                      .toList(),
                ),

                _buildTitulo('Adicionales Seleccionados'),
                _buildCard(
                  cotizacion.adicionalesSeleccionados.map((a) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ${a.nombre}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('  Cantidad: ${a.cantidad}'),
                          Text('  Precio: \$${a.precioUnitario.toStringAsFixed(2)}'),
                          Text('  Estado: ${a.estado}'),
                          const Divider()
                        ],
                      )).toList(),
                ),

                _buildTitulo('Pago y Entrega'),
                _buildCard([
                  _item('Forma de Pago:', cotizacion.formaPago ?? '-'),
                  _item('Método de Pago:', cotizacion.metodoPago ?? '-'),
                  _item('Moneda:', cotizacion.moneda ?? '-'),
                  _item('Cuenta:', cotizacion.cuentaSeleccionada ?? '-'),
                  _item('Otro Método:', cotizacion.otroMetodoPago ?? '-'),
                  _item('Entrega en:', cotizacion.entregaEn ?? '-'),
                  _item('Garantía:', cotizacion.garantia ?? '-'),
                  _item('Inicio Entrega:', cotizacion.fechaInicioEntrega?.toIso8601String() ?? '-'),
                  _item('Fin Entrega:', cotizacion.fechaFinEntrega?.toIso8601String() ?? '-'),
                  _item('Semanas Entrega:', cotizacion.semanasEntrega ?? '-'),
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
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
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
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _item(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
