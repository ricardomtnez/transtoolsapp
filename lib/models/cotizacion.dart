class Cotizacion{
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
}