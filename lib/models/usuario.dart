import 'dart:convert';

class Usuario {
  String fullname;
  String departamento;
  String password;
  String email;
  String initials;
  String rol;
  String empresa;

  Usuario({ 
    required this.fullname, 
    required this.departamento, 
    required this.password, 
    required this.email,
    required this.initials,
  this.rol = '',
  this.empresa = '',
  });

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      fullname: map['fullname'] ?? '',
      departamento: map['departamento'] ?? '',
      password: map['password'] ?? '',
      email: map['email'] ?? '',
      initials: map['iniciales'] ?? '',
  rol: map['rol'] ?? '',
  empresa: map['empresa'] ?? map['company'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullname': fullname,
      'departamento': departamento,
      'password': password,
      'email': email,
      'iniciales': initials,
  'rol': rol,
  'empresa': empresa,
    };
  }
  
  String toJson() => json.encode(toMap());

  factory Usuario.fromJson(String jsonString) =>
      Usuario.fromMap(json.decode(jsonString)); 
}
