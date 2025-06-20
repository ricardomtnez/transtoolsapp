import 'dart:convert';

class Cotizacion {
  String folioCotizacion;
  DateTime fechaCotizacion;
  DateTime fechaVigencia;
  String cliente;
  String empresa;
  String telefono;
  String correo;
  String producto;
  String linea;
  int numeroEjes;
  String modelo;
  int edicion;

  Cotizacion({
    required this.folioCotizacion,
    required this.fechaCotizacion,
    required this.fechaVigencia,
    required this.cliente,
    required this.empresa,
    required this.telefono,
    required this.correo,
    required this.producto,
    required this.linea,
    required this.numeroEjes,
    required this.modelo,
    required this.edicion,
  });

  factory Cotizacion.fromMap(Map<String, dynamic> map) {
    return Cotizacion(
      folioCotizacion: map['folioCotizacion'] ?? '',
      fechaCotizacion: DateTime.parse(map['fechaCotizacion']),
      fechaVigencia: DateTime.parse(map['fechaVigencia']),
      cliente: map['cliente'] ?? '',
      empresa: map['empresa'] ?? '',
      telefono: map['telefono'] ?? '',
      correo: map['correo'] ?? '',
      producto: map['producto'] ?? '',
      linea: map['linea'] ?? '',
      numeroEjes: map['numeroEjes'] ?? 0,
      modelo: map['modelo'] ?? '',
      edicion: map['edicion'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'folioCotizacion': folioCotizacion,
      'fechaCotizacion': fechaCotizacion.toIso8601String(),
      'fechaVigencia': fechaVigencia.toIso8601String(),
      'cliente': cliente,
      'empresa': empresa,
      'telefono': telefono,
      'correo': correo,
      'producto': producto,
      'linea': linea,
      'numeroEjes': numeroEjes,
      'modelo': modelo,
      'edicion': edicion,
    };
  }

  String toJson() => json.encode(toMap());

  factory Cotizacion.fromJson(String jsonString) =>
      Cotizacion.fromMap(json.decode(jsonString));
}
