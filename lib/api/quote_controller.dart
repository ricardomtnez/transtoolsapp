import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:transtools/models/cotizacion.dart';
import 'package:transtools/models/usuario.dart';


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

  //Método que permite obtener los modelos de los productos seleccionados sin por (Producto, Línea, Ejes)
    static Future<List<Map<String, String>>> obtenerModelosPorGrupoSinFiltros(
    String grupoId,
  ) async {
    const boardId = 4863963204;
    final query = '''
      query {
        boards(ids: $boardId) {
          groups(ids: ["$grupoId"]) {
            items_page(limit: 100) {
              items {
                id
                name
                column_values {
                  id
                  column { title }
                  text
                  ... on BoardRelationValue { linked_items { name } }
                  ... on MirrorValue { display_value }
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
          final columnValues = item['column_values'] as List<dynamic>? ?? [];
          String linea = '';
          String ejes = '';
          String precio = '';
          String estado = '';
          
          for (final col in columnValues) {
            if (col['column']?['title'] == 'Línea') {
              linea = col['text'] ?? '';
            }
            if (col['column']?['title'] == 'Núm. Ejes' || col['column']?['title'] == 'Ejes') {
              ejes = col['text'] ?? '';
            }
            // Aquí es donde extraemos el precio usando el ID correcto (PRECIO FIJO SIN IVA)
            if (col['id'] == 'numeric_mkv8eyqc' || col['id'] == 'numeric_mkpxpkc5') {
              precio = col['display_value'] ?? col['text'] ?? '';
            }
            if (col['id'] == 'estado33') {
            estado = col['text'] ?? '';
          }
          }
          
          return {
            'value': item['id']?.toString() ?? '',
            'producto': item['name']?.toString() ?? '',
            'linea': linea,
            'ejes': ejes,
            'precio': precio, 
            'estado': estado, 
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
     items_page(limit: 100) {
      items {
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
          items_page(limit: 100) {
            items {
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

  /// Obtiene el precio de un producto específico.
  static Future<Map<String, dynamic>> obtenerPrecioProducto(int itemId) async {
    final query = """
    query {
      items(ids: $itemId) {
        name
        column_values(ids: ["numeric_mkv8eyqc", "estado33"]) {
          id
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

      double precio = 0;
      String estado = '';

      for (var col in columnValues) {
        if (col['id'] == 'numeric_mkv8eyqc') {
          final valor = col['display_value'] ?? col['text'] ?? '';
          precio = double.tryParse(valor.replaceAll('\$', '').replaceAll(',', '')) ?? 0;
        }
        if (col['id'] == 'estado33') {
          estado = col['text'] ?? '';
        }
      }

  // removed debug prints

      return {
  // Devolvemos varias claves por compatibilidad con el cálculo
  'precio': precio,
  'subtotal': precio, // alias: algunos consumidores esperan 'subtotal'
  'rentabilidad': 0.0, // si no existe columna, devolvemos 0 por defecto
  'estado': estado,
      };
    } else {
      throw Exception(
        'Error al obtener el precio del producto: ${response.body}',
      );
    }
  }

  static Future<int> obtenerConsecutivoCotizacion(
    String nombreCompleto,
    String mes,
  ) async {
    const boardId = 9523399732;
    final query =
        '''
    query {
      items_page_by_column_values (
        limit: 200,
        board_id: $boardId,
        columns: [
          {column_id: "text_mkshgz4r", column_values: ["$nombreCompleto"]},
          {column_id: "text_mkshpxr7", column_values: ["$mes"]}
        ]
      ) {
        items {
          id
          name
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
      final items = data['data']?['items_page_by_column_values']?['items'];
      if (items is List) {
        return items.length;
      }
      return 0;
    } else {
      throw Exception('Error al consultar cotizaciones: ${response.body}');
    }
  }

  static Future<List<Map<String, String>>> obtenerEjesCompatibles(
    String producto,
    String linea,
  ) async {
    const boardId = 4863963204;
    final query =
        '''
    query {
      boards(ids: $boardId) {
        groups(ids: ["$producto"]) {
          items_page(limit: 100, query_params: {
            rules: [
              { column_id: "text_mks1k9fq", compare_value: ["$linea"] }
            ],
            operator: and
          }) {
            items {
              column_values(ids: ["numeric_mks18d6b"]) {
                text
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
        // Extrae los valores únicos de ejes
        final ejesSet = <String>{};
        for (var item in items) {
          final colVals = item['column_values'] as List?;
          if (colVals != null && colVals.isNotEmpty) {
            final eje = colVals[0]['text']?.toString();
            if (eje != null && eje.isNotEmpty) {
              ejesSet.add(eje);
            }
          }
        }
        // Devuelve la lista para el dropdown
        return ejesSet
            .map(
              (eje) => {
                'value': eje,
                'text': '$eje Eje${eje == "1" ? "" : "s"}',
              },
            )
            .toList();
      }
    }
    throw Exception('Error al obtener ejes compatibles');
  }

  // Método para obtener las cotizaciones realizadas
  static Future<List<Map<String, String>>>
  obtenerCotizacionesRealizadas() async {
    const boardId = 9523399732;
    List<Map<String, String>> todasCotizaciones = [];
    String? cursor;

    do {
      final query = '''
        query {
          boards(ids: $boardId) {
            items_page(limit: 100${cursor != null ? ', cursor: "$cursor"' : ''}) {
              items {
                id
                name
                assets { 
                  public_url
                }
                column_values(ids: [
                  "file_mkshqnfa", 
                  "date",
                  "text_mkv2bz8c",
                  "text_mkshwgaf", 
                  "text_mkshakw7", 
                  "numeric_mkshj6rr", 
                  "text_mkshrf49", 
                  "text_mkshgz4r",
                  "text_mkshpxr7"
                ]) {
                  id
                  text
                  value
                }
              }
              cursor
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
        final items = data['data']?['boards']?[0]?['items_page']?['items'];
        cursor = data['data']?['boards']?[0]?['items_page']?['cursor'];

        if (items is List) {
          todasCotizaciones.addAll(items.map<Map<String, String>>((item) {
            final columns = item['column_values'] as List;
            String getCol(String id) {
              final col = columns.firstWhere(
                (c) => c['id'] == id,
                orElse: () => {},
              );
              return (col['text'] != null && col['text'].toString().isNotEmpty)
                  ? col['text']
                  : (col['value'] ?? '');
            }

            final publicUrl =
                (item['assets'] is List && item['assets'].isNotEmpty)
                ? item['assets'][0]['public_url'] ?? ''
                : '';
            return {
              'cotizacion': item['name'] ?? '',
              'cliente': getCol('text_mkv2bz8c'),
              'archivo_pdf': publicUrl,
              'producto': getCol('text_mkshwgaf'),
              'linea': getCol('text_mkshakw7'),
              'ejes': getCol('numeric_mkshj6rr'),
              'modelo': getCol('text_mkshrf49'),
              'vendedor': getCol('text_mkshgz4r'),
              'date': getCol('date'),
              'mes': getCol('text_mkshpxr7'), 
            };
          }));
        }
      } else {
        throw Exception('Error al obtener cotizaciones: ${response.body}');
      }
    } while (cursor != null);

    return todasCotizaciones;
  }

  //Guarda los datos de la cotización en el tablero cotizaciones
  static Future<int> crearItemCotizacion(
    Cotizacion cotizacion,
    Usuario usuario,
    String mesActual,
  ) async {
    final String folio = cotizacion.folioCotizacion;

    // Preparamos los valores de las columnas, asegúrate de que los ID coincidan con los de Monday
   final Map<String, dynamic> columnas = {
  "text_mkshwgaf": cotizacion.producto,
  "text_mkv2bz8c": cotizacion.cliente,
  "text_mkshakw7": cotizacion.linea,
  "numeric_mkshj6rr": cotizacion.numeroEjes,
  "text_mkshrf49": cotizacion.modelo,
  "text_mkshgz4r": usuario.fullname,
  "text_mkshpxr7": mesActual,
};

final String columnValuesJson = jsonEncode(columnas).replaceAll('"', r'\"');

    const boardId = 9523399732;
    final String mutation =
        '''
      mutation {
        create_item(
          board_id: $boardId,
          group_id: "topics",
          item_name: "$folio",
           column_values: "$columnValuesJson"

        ) {
          id
        }
      }
    ''';

    final response = await http.post(
      Uri.parse('https://api.monday.com/v2'),
      headers: {'Content-Type': 'application/json', 'Authorization': token},
      body: json.encode({'query': mutation}),
    );

    final data = jsonDecode(response.body);

    if (data['data']?['create_item']?['id'] == null) {
      throw Exception(
        'Error al crear ítem en Monday: ${data['errors'] ?? response.body}',
      );
    }

    return int.parse(data['data']['create_item']['id']);
  }

  //Método que sube el archivo a monday
  static Future<void> subirArchivoCotizacionPdf(
    int itemId,
    Uint8List archivoBytes,
    Cotizacion cotizacion,
  ) async {
    final uri = Uri.parse('https://api.monday.com/v2/file');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = token
      ..fields['query'] =
          '''
        mutation (\$file: File!) {
          add_file_to_column(file: \$file, item_id: $itemId, column_id: "file_mkshqnfa") {
            id
          }
        }
      '''
      ..files.add(
        http.MultipartFile.fromBytes(
          'variables[file]',
          archivoBytes,
          filename: '${cotizacion.folioCotizacion}-${cotizacion.cliente}.pdf',
          contentType: MediaType('application', 'pdf'),
        ),
      );

    try {
      final response = await request.send();

      if (response.statusCode != 200) {
        final responseBody = await response.stream.bytesToString();
        throw Exception('Error al subir PDF: $responseBody');
      }
    } catch (e) {
      throw Exception('Fallo al subir archivo a Monday: $e');
    }
  }

  static Future obtenerPrecios() async {}
}
