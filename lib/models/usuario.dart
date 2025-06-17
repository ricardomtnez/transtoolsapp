import 'dart:convert';

class Usuario {
  String fullname;
  String departamento;
  String password;
  String email;
  String initials;

  Usuario({ 
    required this.fullname, 
    required this.departamento, 
    required this.password, 
    required this.email,
    required this.initials,
  });

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      fullname: map['fullname'] ?? '',
      departamento: map['departamento'] ?? '',
      password: map['password'] ?? '',
      email: map['email'] ?? '',
      initials: map['iniciales'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullname': fullname,
      'departamento': departamento,
      'password': password,
      'email': email,
      'iniciales': initials,
    };
  }
  
  String toJson() => json.encode(toMap());

  factory Usuario.fromJson(String jsonString) =>
      Usuario.fromMap(json.decode(jsonString)); 
}
