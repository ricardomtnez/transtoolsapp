import 'dart:convert';
import 'package:http/http.dart' as http;

class QuoteController {
  static const token =
      'eyJhbGciOiJIUzI1NiJ9.eyJ0aWQiOjM4MDk5MjcyMiwiYWFpIjoxMSwidWlkIjo0MDY5NzEwMSwiaWFkIjoiMjAyNC0wNy0wNVQyMTowMjozMi4wMDBaIiwicGVyIjoibWU6d3JpdGUiLCJhY3RpZCI6MTA5Mjg0OTUsInJnbiI6InVzZTEifQ.55PVw2YfNZ7d7DUgqfEOl4vLHlh3MU5QGnwReMl-NpQ'; // Pon tu token de Monday aquí
  static final url = Uri.parse('https://api.monday.com/v2');

  //Método para obtener los grupos que corresponden a los productos para el dropdown
  static Future<List<Map<String, dynamic>>> obtenerGrupos(int boardId) async {
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

  //Método que permite obtener los modelos de los productos seleccionados por (Producto, Línea, Ejes)
  static Future<List<Map<String, String>>> obtenerModelosPorGrupo(
    String producto,
    String linea,
    String ejes,
  ) async {
    const boardId = 4863963204;
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

  //Método que permite extraer todas las estructuras para sacar la ficha técnica del modelo seleccionado
  static Future<List<Map<String, dynamic>>> obtenerGruposEstructura(
    int boardId,
  ) async {
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
        return gruposRaw.map<Map<String, String>>((g) {
          return {
            'value': g['id']?.toString() ?? '',
            'text': g['title']?.toString() ?? '',
          };
        }).toList();
      }
    }

    throw Exception('Error al obtener los grupos desde Monday');
  }

  //Método que obtiene la estructura del modelo seleccionado
  static Future<List<dynamic>> obtenerFichaTecnica(
    String grupoId,
    int boardId,
  ) async {
    //print(grupoId);
    final query =
        """
query {
  boards (ids: $boardId) {
    groups (ids: "$grupoId") {
      items_page {
        items{
        name
        column_values(ids: ["text_mkrvr1vr"]) {
          text
        }
        }
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

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items =
          data['data']?['boards']?[0]?['groups']?[0]?['items_page']?['items'];

      if (items is List) {
        return items.map<Map<String, String>>((item) {
          final name = item['name'] ?? '';
          final columnValues = item['column_values'] as List<dynamic>?;
          final descripcion = columnValues != null && columnValues.isNotEmpty
              ? columnValues[0]['text']?.toString() ?? ''
              : '';

          return {'configuracion': name, 'descripcion': descripcion};
        }).toList();
      } else {
        throw Exception('No se encontraron items');
      }
    } else {
      throw Exception('Error en la petición: ${response.statusCode}');
    }
  }

  //Método que permite obtener los kits del modelo seleccionado que se encuentran en los subelementos
  static Future<List<Map<String, dynamic>>> obtenerKitsAdicionales(
    int itemId,
  ) async {
    final query =
        """
      query {
  items (ids: $itemId) {
    subitems {
      name
      column_values(ids:["board_relation_mknywcmq", "numeric_mknyht35", "lookup_mknyt0v4"]) {
        column{
          title
        }
        text
        ... on BoardRelationValue {
        display_value
        
      }
        ... on MirrorValue {
        display_value
      }
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

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final subitems = data['data']['items'][0]['subitems'] as List<dynamic>;

      return subitems.map<Map<String, dynamic>>((subitem) {
        final name = subitem['name'] ?? '';
        final columnValues = subitem['column_values'] as List<dynamic>;

        String adicional = '';
        int cantidad = 0;
        double precio = 0;

        for (var col in columnValues) {
          final title = col['column']['title'];
          final displayValue = col['display_value'];
          final textValue = col['text'];

          if (title == 'ADICIONALES') {
            adicional = displayValue ?? '';
          } else if (title == 'CANTIDAD') {
            cantidad = int.tryParse(textValue ?? '0') ?? 0;
          } else if (title == 'COSTO X UNIDAD') {
            precio = double.tryParse(displayValue ?? '0') ?? 0;
          }
        }
        final descripcionCompleta = "$cantidad KIT DE $adicional";

        return {
          'name': name,
          'adicionales': descripcionCompleta,
          'cantidad': cantidad,
          'precio': precio,
        };
      }).toList();
    } else {
      throw Exception(
        'Error al obtener los kits adicionales: ${response.body}',
      );
    }
  }

  //
  static Future<List<Map<String, dynamic>>> obtenerCategoriasAdicionales(
    int boardId,
  ) async {
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

      if (data['data'] != null &&
          data['data']['boards'] != null &&
          data['data']['boards'].isNotEmpty) {
        final grupos = data['data']['boards'][0]['groups'] as List<dynamic>;
        return grupos
            .map<Map<String, dynamic>>(
              (g) => {'value': g['id'], 'text': g['title']},
            )
            .toList();
      } else {
        throw Exception('No se encontraron categorías en el board');
      }
    } else {
      throw Exception('Error al consultar categorías: ${response.body}');
    }
  }

  //
  static Future<List<Map<String, String>>> obtenerAdicionalesPorCategoria(
    String grupoId,
  ) async {
    const boardId = 8890947131;
    final query =
        '''
    query {
      boards(ids: $boardId) {
        groups(ids: ["$grupoId"]) {
            items_page {
              items{
              name
              column_values(ids: ["reflejo3", "n_meros81", "numeric_mkp11qxn", "n_meros5", "estado33"]){
                column {
                  title
                }
                text
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

      final groups = data['data']['boards'][0]['groups'] as List<dynamic>?;
      if (groups == null || groups.isEmpty) return [];

      final items = groups[0]['items_page']['items'] as List<dynamic>;

      return items.map<Map<String, String>>((item) {
        final columnValues = item['column_values'] as List<dynamic>;

        String? costoMateriales;
        String? rentabilidad;
        String? manoObra;
        String? ponderacion;
        String? estado;

        for (var col in columnValues) {
          final title = col['column']['title'];
          if (title == 'Costo de Materiales') {
            costoMateriales = col['display_value'] ?? '0';
          } else if (title == 'Rentabilidad/Ganancia Esperada') {
            rentabilidad = col['text'] ?? '0';
          } else if (title == 'Mano de Obra Estandár') {
            manoObra = col['text'] ?? '0';
          } else if (title == 'Ponderación') {
            ponderacion = col['text'] ?? '0';
          } else if (title == 'Estado del costeo') {
            estado = col['text'] ?? '';
          }
        }

        // Cálculo seguro
        final costo = double.tryParse(costoMateriales ?? '0') ?? 0;
        final manoObraVal = double.tryParse(manoObra ?? '0') ?? 0;
        final ponderacionVal = double.tryParse(ponderacion ?? '0') ?? 0;
        final rentabilidadVal = double.tryParse(rentabilidad ?? '0') ?? 0;

        final base = costo + (manoObraVal * ponderacionVal);
        final precioFinal = (base / (1 - (rentabilidadVal / 100))) / 1.16;

        return {
          'name': item['name'] ?? '',
          'precio': precioFinal.toStringAsFixed(3),
          'estado': estado ?? '',
        };
      }).toList();
    }

    throw Exception('Error al obtener modelos');
  }

  static Future<Map<String, dynamic>> obtenerPrecioProducto(int itemId) async {
    final query =
        """
    query {
      items(ids: $itemId) {
        name
        column_values(ids: ["reflejo3", "n_meros81", "numeric_mkp11qxn", "n_meros5", "estado33"]) {
          column {
            title
          }
          text
          ... on MirrorValue {
            display_value
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

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final item = data['data']['items'][0];
      final columnValues = item['column_values'] as List;

      double costoMateriales = 0;
      double manoObra = 0;
      double ponderacion = 0;
      double rentabilidad = 0;

      for (var col in columnValues) {
        final title = col['column']['title'];
        final display = col['display_value'] ?? col['text'] ?? '';

        if (title == "Costo de Materiales") {
          costoMateriales = double.tryParse(display) ?? 0;
        } else if (title == "Mano de Obra Estandár") {
          manoObra = double.tryParse(display) ?? 0;
        } else if (title == "Ponderación") {
          ponderacion = double.tryParse(display) ?? 0;
        } else if (title == "Rentabilidad/Ganancia Esperada") {
          rentabilidad = double.tryParse(display) ?? 0;
        }
      }

      final subtotal = costoMateriales + (manoObra * ponderacion);
      final rentabilidadPorcentaje = rentabilidad / 100;

      return {'subtotal': subtotal, 'rentabilidad': rentabilidadPorcentaje};
    } else {
      throw Exception(
        'Error al obtener el precio del producto: ${response.body}',
      );
    }
  }
}
