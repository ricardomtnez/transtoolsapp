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

        for (var col in columnValues) {
          final title = col['column']?['title'];
          if (title == 'Departamento/Área') {
            departamento = col['text'] ?? '';
          } else if (title == 'Contraseña') {
            password = col['text'] ?? '';
          } else if (title == 'Iniciales') {
            initials = col['text'] ?? '';
          } else if (col['column']?['id'] == 'text_mkvw1k8n' || title == 'Rol') {
            // Columna de rol (id: text_mkvw1k8n)
            rol = col['text'] ?? '';
          }
        }

        // Puedes retornar la información relevante como un mapa
        return {
          'fullname': name,
          'departamento': departamento,
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
