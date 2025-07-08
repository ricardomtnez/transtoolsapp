class AdicionalSeleccionado {
  final String nombre;
  final double precioUnitario;
  final int cantidad;
  final String estado;

  AdicionalSeleccionado({
    required this.nombre,
    required this.precioUnitario,
    required this.cantidad,
    required this.estado,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'precioUnitario': precioUnitario,
      'cantidad': cantidad,
      'estado': estado,
    };
  }

  factory AdicionalSeleccionado.fromMap(Map<String, dynamic> map) {
    return AdicionalSeleccionado(
      nombre: map['nombre'],
      precioUnitario: map['precioUnitario'],
      cantidad: map['cantidad'],
      estado: map['estado'],
    );
  }
}
