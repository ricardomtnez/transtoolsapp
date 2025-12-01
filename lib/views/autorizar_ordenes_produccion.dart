import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AutorizarOrdenesProduccionPage extends StatefulWidget {
  static const routeName = '/autorizarOrdenesProduccion';

  const AutorizarOrdenesProduccionPage({Key? key}) : super(key: key);

  @override
  State<AutorizarOrdenesProduccionPage> createState() => _AutorizarOrdenesProduccionPageState();
}

class _AutorizarOrdenesProduccionPageState extends State<AutorizarOrdenesProduccionPage> {
  List<Map<String, dynamic>> ordenes = [];
  bool loading = true;
  String search = '';
  String? filtroVendedor;
  String sortOrder = 'ascendente'; // 'ascendente' | 'descendente'

  @override
  void initState() {
    super.initState();
    _cargarOrdenesMock();
  }

  Future<void> _cargarOrdenesMock() async {
    setState(() => loading = true);
    await Future.delayed(const Duration(milliseconds: 300));

    ordenes = [
      {
        'id': 'COT-EVE11-0011',
        'cliente': 'Cliente D',
        'producto': 'Plataforma',
        'cantidad': 3,
        'fecha': DateTime(2025, 11, 25).toIso8601String(),
        'estado': 'Pendiente',
        'motivoRechazo': null,
        'seleccionada': false,
        'vendedor': 'Benito García',
      },
      {
        'id': 'COT-EVE11-0012',
        'cliente': 'Cliente E',
        'producto': 'Tanque cisterna',
        'cantidad': 1,
        'fecha': DateTime(2025, 11, 23).toIso8601String(),
        'estado': 'Pendiente',
        'motivoRechazo': null,
        'seleccionada': false,
        'vendedor': 'Fernando Anzures',
      },
      {
        'id': 'COT-EVE11-0013',
        'cliente': 'Cliente F',
        'producto': 'Remolque cerrado',
        'cantidad': 5,
        'fecha': DateTime(2025, 11, 21).toIso8601String(),
        'estado': 'Pendiente',
        'motivoRechazo': null,
        'seleccionada': false,
        'vendedor': 'Karla Santos',
      },
    ];

    setState(() => loading = false);
  }

  List<Map<String, dynamic>> get _filtradas {
    final q = search.trim().toLowerCase();
    final lista = ordenes.where((o) {
      if (q.isNotEmpty) {
        final inId = o['id'].toString().toLowerCase().contains(q);
        final inCliente = o['cliente'].toString().toLowerCase().contains(q);
        final inProducto = o['producto'].toString().toLowerCase().contains(q);
        if (!(inId || inCliente || inProducto)) return false;
      }
      if (filtroVendedor != null && filtroVendedor != o['vendedor']) return false;
      return true;
    }).toList();

    lista.sort((a, b) {
      final aId = a['id'].toString();
      final bId = b['id'].toString();
      return sortOrder == 'ascendente' ? aId.compareTo(bId) : bId.compareTo(aId);
    });

    return lista;
  }

  List<String> get _vendedoresUnicos {
    final set = <String>{};
    for (final o in ordenes) {
      if (o['vendedor'] != null) set.add(o['vendedor'].toString());
    }
    final list = set.toList()..sort();
    return list;
  }

  Map<String, Map<String, Color>> get _coloresVendedor {
    return {
      'Benito García': {
        'bg': Colors.purple.shade50,
        'border': Colors.purple.shade200,
        'text': Colors.purple.shade700,
      },
      'Fernando Anzures': {
        'bg': Colors.teal.shade50,
        'border': Colors.teal.shade200,
        'text': Colors.teal.shade700,
      },
      'Karla Santos': {
        'bg': Colors.pink.shade50,
        'border': Colors.pink.shade200,
        'text': Colors.pink.shade700,
      },
      'Juan García': {
        'bg': Colors.blue.shade50,
        'border': Colors.blue.shade200,
        'text': Colors.blue.shade700,
      },
      'María López': {
        'bg': Colors.green.shade50,
        'border': Colors.green.shade200,
        'text': Colors.green.shade700,
      },
      'Carlos Rodríguez': {
        'bg': Colors.orange.shade50,
        'border': Colors.orange.shade200,
        'text': Colors.orange.shade700,
      },
    };
  }

  void _seleccionarTodas(bool value) {
    setState(() {
      for (final o in _filtradas) {
        final idx = ordenes.indexWhere((x) => x['id'] == o['id']);
        if (idx != -1) ordenes[idx]['seleccionada'] = value;
      }
    });
  }

  void _aprobarSeleccionadas() async {
    final indices = <int>[];
    for (var i = 0; i < ordenes.length; i++) {
      if (ordenes[i]['seleccionada'] == true) indices.add(i);
    }
    if (indices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay órdenes seleccionadas')));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text('¿Aprobar ${indices.length} orden(es)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Aprobar')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      for (final i in indices) {
        ordenes[i]['estado'] = 'Aprobada';
        ordenes[i]['seleccionada'] = false;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${indices.length} orden(es) aprobada(s)')));
  }

  void _cancelarSeleccionadas() {
    setState(() {
      for (final o in ordenes) {
        if (o['seleccionada'] == true) {
          o['estado'] = 'Cancelada';
          o['seleccionada'] = false;
        }
      }
    });
  }

  void _restaurarSeleccionadas() {
    setState(() {
      for (final o in ordenes) {
        if (o['seleccionada'] == true) {
          o['estado'] = 'Pendiente';
          o['motivoRechazo'] = null;
          o['seleccionada'] = false;
        }
      }
    });
  }

  int get _conteoSeleccionadas => ordenes.where((o) => o['seleccionada'] == true).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Órdenes por Autorizar'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      backgroundColor: const Color(0xFF2E7D32),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: (v) => setState(() => search = v),
                              decoration: InputDecoration(
                                hintText: 'Buscar por ID, cliente o producto',
                                prefixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(onPressed: () => setState(() => search = ''), icon: const Icon(Icons.clear, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButton<String?>(
                              value: filtroVendedor,
                              hint: const Text('Filtrar por vendedor', style: TextStyle(color: Colors.white)),
                              dropdownColor: const Color(0xFF2E7D32),
                              items: [
                                const DropdownMenuItem<String?>(value: null, child: Text('Todos los vendedores', style: TextStyle(color: Colors.white))),
                                ..._vendedoresUnicos.map((v) => DropdownMenuItem<String?>(value: v, child: Text(v, style: const TextStyle(color: Colors.white)))),
                              ],
                              onChanged: (v) => setState(() => filtroVendedor = v),
                              isExpanded: true,
                              underline: Container(height: 2, color: Colors.white70),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () => setState(() => sortOrder = sortOrder == 'ascendente' ? 'descendente' : 'ascendente'),
                            icon: Icon(sortOrder == 'ascendente' ? Icons.arrow_upward : Icons.arrow_downward, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: _filtradas.isNotEmpty && _filtradas.every((o) => o['seleccionada'] == true),
                            onChanged: (v) => _seleccionarTodas(v == true),
                            activeColor: const Color(0xFF6A1B9A),
                            checkColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          const Text('Seleccionar todos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : _filtradas.isEmpty
                          ? const Center(child: Padding(padding: EdgeInsets.all(24.0), child: Text('No hay órdenes que coincidan', style: TextStyle(color: Colors.white))))
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              itemCount: _filtradas.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, i) {
                                final orden = _filtradas[i];
                                final originalIndex = ordenes.indexWhere((o) => o['id'] == orden['id']);
                                return Card(
                                  color: const Color(0xFFF7F3F8),
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(8, 12, 12, 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Table(
                                          columnWidths: const {
                                            // Columna pequeña para checkbox, columna amplia para vendedor/ID/fecha, columna fija para badges
                                            0: FixedColumnWidth(48),
                                            1: FlexColumnWidth(3),
                                            2: FixedColumnWidth(120),
                                          },
                                          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                          children: [
                                            // Row 1: (empty) | vendedor badge | estado badge
                                            TableRow(children: [
                                              const SizedBox.shrink(),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                                                child: Align(alignment: Alignment.centerRight, child: _buildVendedorBadge(orden['vendedor'] ?? 'Sin vendedor')),
                                              ),
                                              Align(alignment: Alignment.centerRight, child: _buildEstadoBadge(orden['estado'] ?? 'Pendiente')),
                                            ]),
                                            // Row 2: checkbox | ID | Cliente
                                            TableRow(children: [
                                              Align(
                                                alignment: Alignment.center,
                                                child: Checkbox(
                                                  value: orden['seleccionada'] ?? false,
                                                  onChanged: (v) => setState(() => ordenes[originalIndex]['seleccionada'] = v ?? false),
                                                  activeColor: const Color.fromARGB(255, 5, 145, 5),
                                                  checkColor: Colors.white,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                                                child: Align(alignment: Alignment.centerRight, child: Text(orden['id'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                                                child: Align(alignment: Alignment.centerRight, child: Text(orden['cliente'] ?? '', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600))),
                                              ),
                                            ]),
                                            // Row 3: (empty small col) | Fecha | Cantidad
                                            TableRow(children: [
                                              const SizedBox.shrink(),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
                                                child: Align(alignment: Alignment.centerRight, child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.calendar_today, size: 16, color: Colors.grey), const SizedBox(width: 6), Text(DateFormat('dd/MM/yyyy').format(DateTime.parse(orden['fecha'])), style: TextStyle(color: Colors.grey[700]))])),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
                                                child: Align(alignment: Alignment.centerRight, child: Text('Cant: ${orden['cantidad']}', style: const TextStyle(fontWeight: FontWeight.w600))),
                                              ),
                                            ]),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        if (orden['estado'] == 'Pendiente')
                                          Padding(padding: const EdgeInsets.only(top: 8.0), child: Text('Selecciona para autorizar', style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic, fontSize: 13)))
                                        else if (orden['estado'] == 'Rechazada' && orden['motivoRechazo'] != null)
                                          Padding(padding: const EdgeInsets.only(top: 8.0), child: Text('Motivo: ${orden['motivoRechazo']}', style: const TextStyle(color: Color(0xFFD32F2F)))),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _conteoSeleccionadas > 0 ? 1 : 0,
                child: _conteoSeleccionadas > 0
                    ? Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 3))]),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Padding(padding: const EdgeInsets.only(bottom: 12.0), child: Text('$_conteoSeleccionadas Elemento${_conteoSeleccionadas != 1 ? 's' : ''} seleccionado${_conteoSeleccionadas != 1 ? 's' : ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2E7D32)))),
                          Row(children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _aprobarSeleccionadas,
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Autorizar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _cancelarSeleccionadas,
                                icon: const Icon(Icons.cancel),
                                label: const Text('Cancelar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFB703),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _restaurarSeleccionadas,
                                icon: const Icon(Icons.restore),
                                label: const Text('Restaurar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F74C0),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ])
                        ]),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendedorBadge(String vendedor) {
    final colores = _coloresVendedor[vendedor] ?? _coloresVendedor['Juan García']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: colores['bg'], borderRadius: BorderRadius.circular(14), border: Border.all(color: colores['border']!)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.person, size: 13, color: colores['text']), const SizedBox(width: 6), Text(vendedor, style: TextStyle(color: colores['text'], fontWeight: FontWeight.w500, fontSize: 13))]),
    );
  }

  Widget _buildEstadoBadge(String estado) {
    final bg = estado == 'Pendiente' ? Colors.orange.shade50 : estado == 'Aprobada' ? Colors.green.shade50 : Colors.red.shade50;
    final color = estado == 'Pendiente' ? Colors.orange.shade800 : estado == 'Aprobada' ? Colors.green.shade800 : Colors.red.shade800;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)), child: Text(estado, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 14)));
  }
}

