import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transtools/models/usuario.dart';
import 'package:http/http.dart' as http;

class LoginController {
  final String token =
      'eyJhbGciOiJIUzI1NiJ9.eyJ0aWQiOjM4MDk5MjcyMiwiYWFpIjoxMSwidWlkIjo0MDY5NzEwMSwiaWFkIjoiMjAyNC0wNy0wNVQyMTowMjozMi4wMDBaIiwicGVyIjoibWU6d3JpdGUiLCJhY3RpZCI6MTA5Mjg0OTUsInJnbiI6InVzZTEifQ.55PVw2YfNZ7d7DUgqfEOl4vLHlh3MU5QGnwReMl-NpQ'; // Pon tu token de Monday aquí
  final int boardId = 9242939878; // Cambia por el ID real de tu board

  Future<Map<String, dynamic>?> loginUser(String email) async {
    final url = Uri.parse('https://api.monday.com/v2');

    final query =
        """
query {
  items_page_by_column_values(
    limit: 1,
    board_id: $boardId,
    columns:[
      {column_id: "text_mkrb377n", column_values: ["$email"]},
    ]
  ){
    cursor
    items{
      name,
      column_values{
        column{
          id
          title
        }
        value,
        text
      }
    }
  }
}
""";

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'Authorization': token},
      body: jsonEncode({'query': query}),
    );
    //print(response.body);
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      final items =
          data['data']?['items_page_by_column_values']?['items']
              as List<dynamic>?;

      if (items != null && items.isNotEmpty) {
        final firstItem = items[0];

        final name = firstItem['name'] as String? ?? '';
        final columnValues = firstItem['column_values'] as List<dynamic>? ?? [];

  String departamento = '';
  String password = '';
  String initials = '';
  String rol = '';
  String empresa = '';

        for (var col in columnValues) {
          final title = (col['column']?['title'] ?? '').toString();
          final titleLower = title.toLowerCase();
          final colId = (col['column']?['id'] ?? '').toString();

          // Obtener texto preferente: text, si no existe intentar decodificar value
          String colText = col['text']?.toString() ?? '';
          if (colText.toString().trim().isEmpty && col['value'] != null) {
            try {
              final decoded = jsonDecode(col['value'].toString());
              if (decoded is Map && decoded['text'] != null) {
                colText = decoded['text'].toString();
              } else if (decoded is String) {
                colText = decoded;
              } else {
                colText = decoded.toString();
              }
            } catch (_) {
              // si no es JSON, usar el valor crudo
              colText = col['value']?.toString() ?? '';
            }
          }

          if (title == 'Departamento/Área' || titleLower.contains('departamento')) {
            departamento = colText;
          } else if (title == 'Contraseña' || titleLower.contains('contrase')) {
            password = colText;
          } else if (title == 'Iniciales' || titleLower.contains('inicial')) {
            initials = colText;
          } else if (titleLower.contains('empresa') || colId == 'text_mkw1vdvx') {
            // Columna Empresa (id: text_mkw1vdvx) o título que contiene 'empresa'
            empresa = colText;
          } else if (colId == 'text_mkvw1k8n' || titleLower.contains('rol')) {
            // Columna de rol (id: text_mkvw1k8n)
            rol = colText;
          }
        }

        // Puedes retornar la información relevante como un mapa
        return {
          'fullname': name,
          'departamento': departamento,
          'empresa': empresa,
          'password': password,
          'iniciales': initials,
          'rol': rol,
        };
      } else {
        // No se encontró usuario
        return null;
      }
    } else {
      throw Exception(
        'Error en la conexión con monday.com: ${response.statusCode}',
      );
    }
  }

  /// Devuelve la ruta del asset del logo según el nombre de la empresa.
  /// - Si el nombre contiene 'kenworth' (case-insensitive) devuelve
  ///   'assets/Kenworth-logo.png'.
  /// - En cualquier otro caso devuelve 'assets/transtools_logo_white.png'.
  static String assetLogoForEmpresa(String? empresa) {
    final e = (empresa ?? '').toString().trim().toLowerCase();
    if (e.contains('kenworth')) {
      return 'assets/Kenworth-logo.png';
    }
    // Por defecto Transtools
    return 'assets/transtools_logo_white.png';
  }

  /// Lee el usuario almacenado en SharedPreferences y retorna la ruta al
  /// asset del logo correspondiente a su empresa. Si no hay usuario, retorna
  /// el logo por defecto de Transtools.
  Future<String> assetLogoFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('usuario');
    if (json == null || json.isEmpty) return assetLogoForEmpresa(null);
    try {
      // Nota: el modelo Usuario actual no tiene campo 'empresa'. Intentamos
      // leer 'empresa' del JSON crudo si fue guardado allí.
      final Map<String, dynamic> mapa = jsonDecode(json);
      // ignore: unnecessary_null_in_if_null_operators
      final empresa = mapa['empresa'] ?? mapa['company'] ?? null;
      return assetLogoForEmpresa(empresa?.toString());
    } catch (_) {
      return assetLogoForEmpresa(null);
    }
  }

  /// Filtra la lista de grupos en base al rol del usuario almacenado.
  
  Future<List<Map<String, dynamic>>> filterGruposByRole(List<dynamic> grupos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('usuario');
      if (json == null || json.isEmpty) return List<Map<String, dynamic>>.from(grupos);
      final usuario = Usuario.fromJson(json);
      final role = usuario.rol.toString().trim().toLowerCase();

  if (role.startsWith('miem') || role == 'member') {
        // ignore: no_leading_underscores_for_local_identifiers
        String _normalize(String s) {
          return s
              .replaceAll('Á', 'A')
              .replaceAll('É', 'E')
              .replaceAll('Í', 'I')
              .replaceAll('Ó', 'O')
              .replaceAll('Ú', 'U')
              .replaceAll('á', 'a')
              .replaceAll('é', 'e')
              .replaceAll('í', 'i')
              .replaceAll('ó', 'o')
              .replaceAll('ú', 'u')
              .replaceAll('Ñ', 'N')
              .replaceAll('ñ', 'n');
        }

        final filtered = grupos.where((g) {
          final text = (g['text'] ?? '').toString();
          final normalized = _normalize(text).toLowerCase();
          return !normalized.contains('personaliz');
        }).toList();
        return List<Map<String, dynamic>>.from(filtered);
      }
      return List<Map<String, dynamic>>.from(grupos);
    } catch (e) {
      return List<Map<String, dynamic>>.from(grupos);
    }
  }
}
