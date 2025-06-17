import 'dart:convert';
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

        for (var col in columnValues) {
          final title = col['column']?['title'];
          if (title == 'Departamento/Área') {
            departamento = col['text'] ?? '';
          } else if (title == 'Contraseña') {
            password = col['text'] ?? '';
          } else if (title == 'Iniciales') {
            initials = col['text'] ?? '';
          }
        }

        // Puedes retornar la información relevante como un mapa
        return {
          'fullname': name,
          'departamento': departamento,
          'password': password,
          'iniciales': initials,
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
}
