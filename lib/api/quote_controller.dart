import 'dart:convert';
import 'package:http/http.dart' as http;

class QuoteController {
  static Future<List<Map<String, dynamic>>> obtenerGrupos() async {
    const boardId = 4863963204; // Reemplaza con tu board ID real
    const token =
        'eyJhbGciOiJIUzI1NiJ9.eyJ0aWQiOjM4MDk5MjcyMiwiYWFpIjoxMSwidWlkIjo0MDY5NzEwMSwiaWFkIjoiMjAyNC0wNy0wNVQyMTowMjozMi4wMDBaIiwicGVyIjoibWU6d3JpdGUiLCJhY3RpZCI6MTA5Mjg0OTUsInJnbiI6InVzZTEifQ.55PVw2YfNZ7d7DUgqfEOl4vLHlh3MU5QGnwReMl-NpQ'; // Pon tu token de Monday aquí
    final url = Uri.parse('https://api.monday.com/v2');

    final query =
        """
query {
  boards(ids: $boardId) {
    groups {
      id
      title
    }
  }
}
""";
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'Authorization': token},
      body: jsonEncode({'query': query}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final gruposRaw = data['data']?['boards']?[0]?['groups'];

      if (gruposRaw is List) {
        // Filtrar grupos que contengan "plantilla" (ignorando mayúsculas/minúsculas)
        final gruposFiltrados = gruposRaw.where((g) {
          final title = g['title']?.toString().toLowerCase() ?? '';
          return title.contains('plantilla');
        }).toList();

        return gruposFiltrados.map<Map<String, String>>((g) {
          final originalTitle = g['title']?.toString() ?? '';
          final cleanedTitle = originalTitle
              .replaceAll(RegExp(r'plantilla', caseSensitive: false), '')
              .trim();

          return {'value': g['id']?.toString() ?? '', 'text': cleanedTitle};
        }).toList();
      }
    }

    throw Exception('Error al obtener los grupos desde Monday');
  }

  static Future<List<Map<String, String>>> obtenerModelosPorGrupo(
    String producto,
    String linea,
    String ejes,
  ) async {
    print(producto);
    print(linea);
    print(ejes);
    final url = Uri.parse('https://api.monday.com/v2');
    const boardId = 4863963204;
    const token =
        'eyJhbGciOiJIUzI1NiJ9.eyJ0aWQiOjM4MDk5MjcyMiwiYWFpIjoxMSwidWlkIjo0MDY5NzEwMSwiaWFkIjoiMjAyNC0wNy0wNVQyMTowMjozMi4wMDBaIiwicGVyIjoibWU6d3JpdGUiLCJhY3RpZCI6MTA5Mjg0OTUsInJnbiI6InVzZTEifQ.55PVw2YfNZ7d7DUgqfEOl4vLHlh3MU5QGnwReMl-NpQ'; // Pon tu token de Monday aquí

    final query =
        '''
    query {
      boards(ids: $boardId) {
        groups(ids: ["$producto"]) {
          items_page(limit: 50, query_params: {
            rules: [
              { column_id: "text_mks1k9fq", compare_value: ["$linea"] },
              { column_id: "numeric_mks18d6b", compare_value: ["$ejes"] }
            ],
            operator: and
          }) {
            items {
              id
              name
              column_values {
                id
                column {
                  title
                }
                text
                ... on BoardRelationValue {
                  linked_items {
                    name
                  }
                }
                ... on MirrorValue {
                  display_value
                }
              }
            }
          }
        }
      }
    }
  ''';

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'Authorization': token},
      body: jsonEncode({'query': query}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items =
          data['data']?['boards']?[0]?['groups']?[0]?['items_page']?['items'];

      if (items is List) {
        return items.map<Map<String, String>>((item) {
          return {
            'value': item['id']?.toString() ?? '',
            'text': item['name']?.toString() ?? '',
          };
        }).toList();
      }
    }

    throw Exception('Error al obtener modelos');
  }
}
