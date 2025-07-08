import 'dart:convert';

import 'package:transtools/models/adicional_seleccionado.dart';

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
  String color;
  String marcaColor;
  int generacion;

  // Guarda la estructura del producto (puede ser Map o List)
  Map<String, dynamic> estructura;

  // Guarda los adicionales de línea, que es una lista
  List<dynamic> adicionalesDeLinea;

  // Guarda los adicionales seleccionados, con detalles (nombre, cantidad, precio, estado)
  List<AdicionalSeleccionado> adicionalesSeleccionados;

  // NUEVOS CAMPOS de Sección 3
  int numeroUnidades;
  String? formaPago;
  String? metodoPago;
  String? moneda;
  String? entregaEn;
  String? garantia;
  String? cuentaSeleccionada;
  String? otroMetodoPago;
  DateTime? fechaInicioEntrega;
  DateTime? fechaFinEntrega;
  String? semanasEntrega;

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
    required this.color,
    required this.marcaColor,
    required this.generacion,
    this.estructura = const {},
    this.adicionalesDeLinea = const [],
    this.adicionalesSeleccionados = const [],
    this.numeroUnidades = 1,
    this.formaPago,
    this.metodoPago,
    this.moneda,
    this.entregaEn,
    this.garantia,
    this.cuentaSeleccionada,
    this.otroMetodoPago,
    this.fechaInicioEntrega,
    this.fechaFinEntrega,
    this.semanasEntrega,
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
      color: map['color'] ?? '',
      marcaColor: map['marcaColor'] ?? '',
      generacion: map['generacion'] ?? 0,
      estructura: Map<String, dynamic>.from(map['estructura'] ?? {}),
      adicionalesDeLinea: List<dynamic>.from(map['adicionalesDeLinea'] ?? []),
      adicionalesSeleccionados:
          (map['adicionalesSeleccionados'] as List<dynamic>?)
              ?.map((a) => AdicionalSeleccionado.fromMap(a))
              .toList() ??
          [],
      numeroUnidades: map['numeroUnidades'] ?? 1,
      formaPago: map['formaPago'],
      metodoPago: map['metodoPago'],
      moneda: map['moneda'],
      entregaEn: map['entregaEn'],
      garantia: map['garantia'],
      cuentaSeleccionada: map['cuentaSeleccionada'],
      otroMetodoPago: map['otroMetodoPago'],
      fechaInicioEntrega: map['fechaInicioEntrega'] != null
          ? DateTime.parse(map['fechaInicioEntrega'])
          : null,
      fechaFinEntrega: map['fechaFinEntrega'] != null
          ? DateTime.parse(map['fechaFinEntrega'])
          : null,
      semanasEntrega: map['semanasEntrega'],
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
      'color': color,
      'marcaColor': marcaColor,
      'generacion': generacion,
      'estructura': estructura,
      'adicionalesDeLinea': adicionalesDeLinea,
      'adicionalesSeleccionados': adicionalesSeleccionados
          .map((a) => a.toMap())
          .toList(),
      'numeroUnidades': numeroUnidades,
      'formaPago': formaPago,
      'metodoPago': metodoPago,
      'moneda': moneda,
      'entregaEn': entregaEn,
      'garantia': garantia,
      'cuentaSeleccionada': cuentaSeleccionada,
      'otroMetodoPago': otroMetodoPago,
      'fechaInicioEntrega': fechaInicioEntrega?.toIso8601String(),
      'fechaFinEntrega': fechaFinEntrega?.toIso8601String(),
      'semanasEntrega': semanasEntrega,
    };
  }

  String toJson() => json.encode(toMap());

  factory Cotizacion.fromJson(String jsonString) =>
      Cotizacion.fromMap(json.decode(jsonString));

  Cotizacion copyWith({
    String? folioCotizacion,
    DateTime? fechaCotizacion,
    DateTime? fechaVigencia,
    String? cliente,
    String? empresa,
    String? telefono,
    String? correo,
    String? producto,
    String? linea,
    int? numeroEjes,
    String? modelo,
    String? color,
    String? marcaColor,
    int? generacion,
    Map<String, dynamic>? estructura,
    List<dynamic>? adicionalesDeLinea,
    List<AdicionalSeleccionado>? adicionalesSeleccionados,
    int? numeroUnidades,
    String? formaPago,
    String? metodoPago,
    String? moneda,
    String? entregaEn,
    String? garantia,
    String? cuentaSeleccionada,
    String? otroMetodoPago,
    DateTime? fechaInicioEntrega,
    DateTime? fechaFinEntrega,
    String? semanasEntrega,
  }) {
    return Cotizacion(
      folioCotizacion: folioCotizacion ?? this.folioCotizacion,
      fechaCotizacion: fechaCotizacion ?? this.fechaCotizacion,
      fechaVigencia: fechaVigencia ?? this.fechaVigencia,
      cliente: cliente ?? this.cliente,
      empresa: empresa ?? this.empresa,
      telefono: telefono ?? this.telefono,
      correo: correo ?? this.correo,
      producto: producto ?? this.producto,
      linea: linea ?? this.linea,
      numeroEjes: numeroEjes ?? this.numeroEjes,
      modelo: modelo ?? this.modelo,
      color: color ?? this.color,
      marcaColor: marcaColor ?? this.marcaColor,
      generacion: generacion ?? this.generacion,
      estructura: estructura ?? this.estructura,
      adicionalesDeLinea: adicionalesDeLinea ?? this.adicionalesDeLinea,
      adicionalesSeleccionados:
          adicionalesSeleccionados ?? this.adicionalesSeleccionados,
      numeroUnidades: numeroUnidades ?? this.numeroUnidades,
      formaPago: formaPago ?? this.formaPago,
      metodoPago: metodoPago ?? this.metodoPago,
      moneda: moneda ?? this.moneda,
      entregaEn: entregaEn ?? this.entregaEn,
      garantia: garantia ?? this.garantia,
      cuentaSeleccionada: cuentaSeleccionada ?? this.cuentaSeleccionada,
      otroMetodoPago: otroMetodoPago ?? this.otroMetodoPago,
      fechaInicioEntrega: fechaInicioEntrega ?? this.fechaInicioEntrega,
      fechaFinEntrega: fechaFinEntrega ?? this.fechaFinEntrega,
      semanasEntrega: semanasEntrega ?? this.semanasEntrega,
    );
  }
}
