import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SeguimientoCotizacionPage extends StatefulWidget {
  final Map<String, String> cotizacion;
  
  const SeguimientoCotizacionPage({
    required this.cotizacion,
    super.key,
  });

  @override
  State<SeguimientoCotizacionPage> createState() => _SeguimientoCotizacionPageState();
}

class _SeguimientoCotizacionPageState extends State<SeguimientoCotizacionPage> {
  List<Map<String, dynamic>> etapas = [];
  bool loading = true;
  bool guardandoCambios = false;
  String? estadoEspecial; // 'cancelada', 'sin_seguimiento', null

  @override
  void initState() {
    super.initState();
    _cargarSeguimiento();
  }

  Future<void> _cargarSeguimiento() async {
    setState(() => loading = true);
    
    // Simulamos la carga de datos de seguimiento
    // Aquí se conectaría con la API real
    await Future.delayed(Duration(seconds: 1));
    
    // Datos de ejemplo para el seguimiento
    etapas = [
      {
        'titulo': 'Cotización Creada',
        'fecha': widget.cotizacion['date'] ?? '',
        'completado': true,
        'descripcion': 'Cotización ${widget.cotizacion['cotizacion']} creada exitosamente',
        'icono': Icons.description,
      },
      {
        'titulo': 'Enviada al Cliente',
        'fecha': '',
        'completado': false,
        'descripcion': 'Cotización enviada a ${widget.cotizacion['cliente']}',
        'icono': Icons.send,
      },
      {
        'titulo': 'En Revisión',
        'fecha': '',
        'completado': false,
        'descripcion': 'Cliente revisando la propuesta',
        'icono': Icons.visibility,
      },
      {
        'titulo': 'En Negociación',
        'fecha': '',
        'completado': false,
        'descripcion': 'En proceso de negociación de términos',
        'icono': Icons.handshake,
      },
      {
        'titulo': 'Cierre',
        'fecha': '',
        'completado': false,
        'descripcion': 'Aprobación final del cliente - Listo para orden de producción',
        'icono': Icons.approval,
      },
    ];

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Seguimiento de Cotización',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
            if (guardandoCambios)
              Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.blue[800],
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Guardando...',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      backgroundColor: Colors.blue[800],
      body: SafeArea(
        child: Column(
          children: [
            // Header con información de la cotización
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description, color: Colors.blue[800], size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.cotizacion['cotizacion'] ?? '',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                            Text(
                              widget.cotizacion['cliente'] ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoChip(
                          'Producto',
                          widget.cotizacion['producto'] ?? '',
                          Icons.inventory_2,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoChip(
                          'Modelo',
                          widget.cotizacion['modelo'] ?? '',
                          Icons.settings,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoChip(
                          'Ejes',
                          widget.cotizacion['ejes'] ?? '',
                          Icons.linear_scale,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoChip(
                          'Fecha',
                          _formatFecha(widget.cotizacion['date'] ?? ''),
                          Icons.calendar_today,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Timeline de seguimiento
            Expanded(
              child: loading
                  ? Center(
                      child: Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 48,
                              width: 48,
                              child: CircularProgressIndicator(
                                color: Colors.blue[800],
                                strokeWidth: 4,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Cargando seguimiento...',
                              style: TextStyle(
                                color: Colors.blue[800],
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            // ignore: deprecated_member_use
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.all(20),
                        itemCount: etapas.length,
                        itemBuilder: (context, index) {
                          final etapa = etapas[index];
                          final isLast = index == etapas.length - 1;
                          final canToggle = _puedeTogglear(index);
                          
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  GestureDetector(
                                    onTap: canToggle ? () => _toggleEtapa(index) : null,
                                    child: AnimatedContainer(
                                      duration: Duration(milliseconds: 300),
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: etapa['completado']
                                            ? Colors.green
                                            : canToggle
                                                ? Colors.orange[400]
                                                : Colors.grey[300],
                                        shape: BoxShape.circle,
                                        border: canToggle && !etapa['completado']
                                            ? Border.all(color: Colors.orange[600]!, width: 2)
                                            : null,
                                      ),
                                      child: Icon(
                                        etapa['completado']
                                            ? Icons.check
                                            : canToggle
                                                ? Icons.radio_button_unchecked
                                                : etapa['icono'],
                                        color: etapa['completado']
                                            ? Colors.white
                                            : canToggle
                                                ? Colors.orange[800]
                                                : Colors.grey[600],
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  if (!isLast)
                                    Container(
                                      width: 2,
                                      height: 80,
                                      color: etapa['completado']
                                          ? Colors.green
                                          : Colors.grey[300],
                                      margin: EdgeInsets.symmetric(vertical: 4),
                                    ),
                                ],
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  margin: EdgeInsets.only(bottom: isLast ? 0 : 20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              etapa['titulo'],
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: estadoEspecial == 'cancelada'
                                                    ? Colors.grey[500]
                                                    : etapa['completado']
                                                        ? Colors.green
                                                        : canToggle
                                                            ? Colors.orange[800]
                                                            : Colors.grey[700],
                                                decoration: estadoEspecial == 'cancelada' 
                                                    ? TextDecoration.lineThrough 
                                                    : TextDecoration.none,
                                              ),
                                            ),
                                          ),
                                          if (canToggle)
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.orange[100],
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.orange[300]!),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.touch_app, 
                                                       color: Colors.orange[800], 
                                                       size: 14),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Toca para cambiar',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.orange[800],
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        etapa['descripcion'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: estadoEspecial == 'cancelada'
                                              ? Colors.grey[500]
                                              : Colors.grey[600],
                                          decoration: estadoEspecial == 'cancelada' 
                                              ? TextDecoration.lineThrough 
                                              : TextDecoration.none,
                                        ),
                                      ),
                                      if (etapa['fecha'].isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            _formatFecha(etapa['fecha']),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue[800],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      // Mostrar tipo de contacto si está completado y tiene tipo de contacto
                                      if (etapa['completado'] && etapa['tipoContacto'] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              // ignore: deprecated_member_use
                                              color: _getColorTipoContacto(etapa['tipoContacto']).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                // ignore: deprecated_member_use
                                                color: _getColorTipoContacto(etapa['tipoContacto']).withOpacity(0.3),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _getIconoTipoContacto(etapa['tipoContacto']),
                                                  color: _getColorTipoContacto(etapa['tipoContacto']),
                                                  size: 14,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'vía ${etapa['tipoContacto']}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: _getColorTipoContacto(etapa['tipoContacto']),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      // Botones de acción para etapas activas
                                      if (canToggle && !etapa['completado'])
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Row(
                                            children: [
                                              ElevatedButton.icon(
                                                onPressed: () => _completarEtapa(index),
                                                icon: Icon(Icons.check_circle, size: 16),
                                                label: Text('Completar'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  foregroundColor: Colors.white,
                                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  textStyle: TextStyle(fontSize: 12),
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              OutlinedButton.icon(
                                                onPressed: () => _editarFecha(index),
                                                icon: Icon(Icons.edit_calendar, size: 16),
                                                label: Text('Editar Fecha'),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.blue[800],
                                                  side: BorderSide(color: Colors.blue[300]!),
                                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  textStyle: TextStyle(fontSize: 12),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
            ),
            
            // Botones de acciones especiales
            if (estadoEspecial == null)
              Container(
                margin: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      '¿Necesitas marcar un estado especial?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _marcarCancelada(),
                            icon: Icon(Icons.cancel_outlined, size: 20),
                            label: Text('Cancelada'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _marcarSinSeguimiento(),
                            icon: Icon(Icons.pause_circle_outlined, size: 20),
                            label: Text('Sin Seguimiento'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[600],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            
            // Mostrar estado especial si existe
            if (estadoEspecial != null)
              Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: estadoEspecial == 'cancelada' ? Colors.red[100] : Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: estadoEspecial == 'cancelada' ? Colors.red[300]! : Colors.orange[300]!,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          estadoEspecial == 'cancelada' ? Icons.cancel : Icons.pause_circle,
                          color: estadoEspecial == 'cancelada' ? Colors.red[700] : Colors.orange[700],
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            estadoEspecial == 'cancelada'
                                ? 'Cotización Cancelada'
                                : 'Sin Seguimiento Activo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: estadoEspecial == 'cancelada' ? Colors.red[700] : Colors.orange[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      estadoEspecial == 'cancelada'
                          ? 'Esta cotización ha sido cancelada por el cliente o por decisión interna.'
                          : 'Esta cotización está pausada y no se le está dando seguimiento actualmente.',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _reactivarSeguimiento,
                      icon: Icon(Icons.refresh, size: 18),
                      label: Text('Reactivar Seguimiento'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[800], size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatFecha(String fecha) {
    if (fecha.isEmpty) return '';
    try {
      final parsedDate = DateTime.parse(fecha);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return fecha;
    }
  }

  Color _getColorTipoContacto(String? tipoContacto) {
    switch (tipoContacto) {
      case 'Correo':
        return Colors.blue[600]!;
      case 'WhatsApp':
        return Colors.green[600]!;
      case 'Llamada':
        return Colors.orange[600]!;
      case 'Presencial':
        return Colors.purple[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _getIconoTipoContacto(String? tipoContacto) {
    switch (tipoContacto) {
      case 'Correo':
        return Icons.email;
      case 'WhatsApp':
        return Icons.chat;
      case 'Llamada':
        return Icons.phone;
      case 'Presencial':
        return Icons.person;
      default:
        return Icons.contact_phone;
    }
  }

  bool _puedeTogglear(int index) {
    // No se puede cambiar nada si hay un estado especial activo
    if (estadoEspecial != null) return false;
    
    // Solo se puede cambiar el estado si todas las etapas anteriores están completadas
    // y esta es la siguiente etapa en proceso
    if (index == 0) return true; // La primera siempre se puede cambiar
    
    for (int i = 0; i < index; i++) {
      if (!etapas[i]['completado']) {
        return false; // Si hay una etapa anterior incompleta, no se puede cambiar esta
      }
    }
    
    // Solo se puede cambiar si es la próxima en la secuencia
    return !etapas[index]['completado'];
  }

  void _toggleEtapa(int index) {
    if (!_puedeTogglear(index)) return;
    
    setState(() {
      etapas[index]['completado'] = !etapas[index]['completado'];
      
      // Si se marca como completada, actualizar la fecha
      if (etapas[index]['completado'] && etapas[index]['fecha'].isEmpty) {
        etapas[index]['fecha'] = DateFormat('yyyy-MM-dd').format(DateTime.now());
      }
      
      // Si se desmarca, limpiar fechas de etapas posteriores
      if (!etapas[index]['completado']) {
        for (int i = index + 1; i < etapas.length; i++) {
          etapas[i]['completado'] = false;
          etapas[i]['fecha'] = '';
        }
      }
    });
    
    _guardarCambios();
  }

  void _completarEtapa(int index) {
    if (!_puedeTogglear(index)) return;
    
    // Verificar si es la etapa adecuada para mostrar el diálogo de revisión.
    // No mostrar el modal en 'En Revisión' — ese botón debe completar directamente.
    if (etapas[index]['titulo'] == 'Visto Bueno' ||
        etapas[index]['titulo'] == 'En Negociación') {
      _mostrarDialogoRevision(index);
    } else if (etapas[index]['titulo'] == 'Cierre') {
      _mostrarDialogoCierre(index);
    } else if (etapas[index]['titulo'] == 'Enviada al Cliente') {
      // Solo para "Enviada al Cliente" mostrar diálogo de tipo de contacto
      _mostrarDialogoTipoContacto(index);
    } else {
      // Para otras etapas, completar directamente sin tipo de contacto
      _completarEtapaDirectamente(index);
    }
  }

  void _mostrarDialogoTipoContacto(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.contact_phone, color: Colors.blue[800], size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tipo de Contacto',
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Cómo fue el contacto para completar esta etapa?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 20),
              // Opciones de contacto
              _buildOpcionContacto(
                index,
                'Correo',
                Icons.email,
                Colors.blue[600]!,
                'Contacto realizado vía correo electrónico',
              ),
              SizedBox(height: 12),
              _buildOpcionContacto(
                index,
                'WhatsApp',
                Icons.chat,
                Colors.green[600]!,
                'Contacto realizado vía WhatsApp',
              ),
              SizedBox(height: 12),
              _buildOpcionContacto(
                index,
                'Llamada',
                Icons.phone,
                Colors.orange[600]!,
                'Contacto realizado vía llamada telefónica',
              ),
              SizedBox(height: 12),
              _buildOpcionContacto(
                index,
                'Presencial',
                Icons.person,
                Colors.purple[600]!,
                'Contacto realizado de manera presencial',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoRevision(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.rate_review, color: Colors.blue[800], size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Resultado de Revisión',
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Cuál fue el resultado de la revisión del cliente?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 20),
              // Opción: Aprobado - continuar al siguiente paso
              _buildOpcionRevision(
                index,
                'Aprobado',
                Icons.thumb_up,
                Colors.green[600]!,
                'El cliente aprobó la cotización sin cambios',
                'aprobado',
              ),
              SizedBox(height: 12),
              // Opción: Solicita cambios
              _buildOpcionRevision(
                index,
                'Solicita Cambios',
                Icons.edit_note,
                Colors.orange[600]!,
                'El cliente solicita modificaciones o ajustes',
                'cambios',
              ),
              SizedBox(height: 12),
              // Opción: Rechazado
              _buildOpcionRevision(
                index,
                'Rechazado',
                Icons.thumb_down,
                Colors.red[600]!,
                'El cliente rechazó la cotización',
                'rechazado',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoCierre(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.approval, color: Colors.green[800], size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Finalizar Cotización',
                  style: TextStyle(
                    color: Colors.green[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600], size: 48),
                    SizedBox(height: 12),
                    Text(
                      '¿Está listo para enviar a "Cotización Aprobada"?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Esta acción completará el proceso de seguimiento y marcará la cotización como aprobada.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'La cotización aparecerá en la sección "Cotizaciones Aprobadas"',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _completarCierreYEnviarAAprobada(index);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.send, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Enviar a Aprobada',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOpcionContacto(int index, String tipo, IconData icono, Color color, String descripcion) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        _completarEtapaConContacto(index, tipo);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
          // ignore: deprecated_member_use
          color: color.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icono, color: Colors.white, size: 20),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tipo,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                  Text(
                    descripcion,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOpcionRevision(int index, String resultado, IconData icono, Color color, String descripcion, String accion) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        _procesarResultadoRevision(index, resultado, accion);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
          // ignore: deprecated_member_use
          color: color.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icono, color: Colors.white, size: 20),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resultado,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                  Text(
                    descripcion,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  void _completarEtapaConContacto(int index, String tipoContacto) {
    setState(() {
      etapas[index]['completado'] = true;
      etapas[index]['tipoContacto'] = tipoContacto; // Guardar el tipo de contacto
      if (etapas[index]['fecha'].isEmpty) {
        etapas[index]['fecha'] = DateFormat('yyyy-MM-dd').format(DateTime.now());
      }
    });
    
    _guardarCambios();
    
    // Verificar si es la última etapa (Aprobación)
    if (index == etapas.length - 1 && etapas[index]['titulo'] == 'Aprobación') {
      _mostrarDialogoAprobacionCompleta();
    } else {
      // Mostrar mensaje de confirmación con el tipo de contacto
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Etapa "${etapas[index]['titulo']}" completada vía $tipoContacto',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _completarEtapaDirectamente(int index) {
    setState(() {
      etapas[index]['completado'] = true;
      if (etapas[index]['fecha'].isEmpty) {
        etapas[index]['fecha'] = DateFormat('yyyy-MM-dd').format(DateTime.now());
      }
    });
    
    _guardarCambios();
    
    // Verificar si es la última etapa (Aprobación)
    if (index == etapas.length - 1 && etapas[index]['titulo'] == 'Aprobación') {
      _mostrarDialogoAprobacionCompleta();
    } else {
      // Mostrar mensaje de confirmación simple
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Etapa "${etapas[index]['titulo']}" completada',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _completarCierreYEnviarAAprobada(int index) {
    setState(() {
      etapas[index]['completado'] = true;
      if (etapas[index]['fecha'].isEmpty) {
        etapas[index]['fecha'] = DateFormat('yyyy-MM-dd').format(DateTime.now());
      }
    });
    
    _guardarCambios();
    
    // Mostrar diálogo de confirmación de envío a cotización aprobada
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              Icon(Icons.celebration, color: Colors.green, size: 48),
              SizedBox(height: 16),
              Text(
                '¡Cotización Completada!',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.cotizacion['cotizacion'] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.cotizacion['cliente'] ?? '',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'La cotización ha sido enviada exitosamente a "Cotización Aprobada" y está lista para generar la orden de producción.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta cotización aparece ahora en "Cotizaciones Aprobadas"',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(); // Cerrar diálogo
                  Navigator.of(context).pop(); // Volver a la lista de cotizaciones
                },
                icon: Icon(Icons.check_circle, size: 20),
                label: Text('Entendido'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _editarFecha(int index) {
    showDatePicker(
      context: context,
      initialDate: etapas[index]['fecha'].isNotEmpty 
          ? DateTime.parse(etapas[index]['fecha']) 
          : DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    ).then((selectedDate) {
      if (selectedDate != null) {
        setState(() {
          etapas[index]['fecha'] = DateFormat('yyyy-MM-dd').format(selectedDate);
        });
        _guardarCambios();
      }
    });
  }

  void _procesarResultadoRevision(int index, String resultado, String accion) {
    if (accion == 'aprobado') {
      // Si fue aprobado, completar directamente sin solicitar tipo de contacto
      _completarRevisionAprobadaDirectamente(index, resultado);
    } else if (accion == 'cambios') {
      // Si solicita cambios, mostrar diálogo para capturar retroalimentación
      _mostrarDialogoRetroalimentacion(index);
    } else if (accion == 'rechazado') {
      // Si fue rechazado, marcar cotización como cancelada
      _procesarRechazo(index);
    }
  }

  void _completarRevisionAprobadaDirectamente(int index, String resultado) {
    setState(() {
      etapas[index]['completado'] = true;
      etapas[index]['resultadoRevision'] = resultado;
      if (etapas[index]['fecha'].isEmpty) {
        etapas[index]['fecha'] = DateFormat('yyyy-MM-dd').format(DateTime.now());
      }
    });
    
    _guardarCambios();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text('Revisión completada: $resultado'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _guardarCambios() async {
    setState(() => guardandoCambios = true);
    
    try {
      // Aquí se enviarían los cambios a la API
      await Future.delayed(Duration(milliseconds: 500)); // Simular guardado
      
      // ignore: unused_local_variable
      for (var etapa in etapas) {
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar cambios: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => guardandoCambios = false);
      }
    }
  }

  void _marcarCancelada() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.red[700], size: 28),
              SizedBox(width: 12),
              Text('Cancelar Cotización', style: TextStyle(color: Colors.red[700])),
            ],
          ),
          content: Text(
            '¿Estás seguro de que quieres marcar esta cotización como cancelada? Esta acción pausará el seguimiento.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  estadoEspecial = 'cancelada';
                });
                _guardarCambios();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.cancel, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Cotización marcada como cancelada'),
                      ],
                    ),
                    backgroundColor: Colors.red[600],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
              child: Text('Confirmar Cancelación', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _marcarSinSeguimiento() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.pause_circle, color: Colors.orange[700], size: 28),
              SizedBox(width: 12),
              Text('Pausar Seguimiento', style: TextStyle(color: Colors.orange[700])),
            ],
          ),
          content: Text(
            '¿Quieres pausar el seguimiento de esta cotización? Podrás reactivarlo más tarde.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  estadoEspecial = 'sin_seguimiento';
                });
                _guardarCambios();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.pause_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Seguimiento pausado'),
                      ],
                    ),
                    backgroundColor: Colors.orange[600],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[600]),
              child: Text('Pausar Seguimiento', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _reactivarSeguimiento() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.refresh, color: Colors.blue[700], size: 28),
              SizedBox(width: 12),
              Text('Reactivar Seguimiento', style: TextStyle(color: Colors.blue[700])),
            ],
          ),
          content: Text(
            '¿Quieres reactivar el seguimiento de esta cotización?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  estadoEspecial = null;
                });
                _guardarCambios();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Seguimiento reactivado'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[600]),
              child: Text('Reactivar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoAprobacionCompleta() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              Icon(Icons.celebration, color: Colors.green, size: 48),
              SizedBox(height: 16),
              Text(
                '¡Cotización Aprobada!',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.cotizacion['cotizacion'] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.cotizacion['cliente'] ?? '',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'La cotización ha completado todo el proceso de seguimiento y está lista para generar la orden de producción.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta cotización aparecerá ahora en "Cotizaciones Aprobadas"',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(); // Cerrar diálogo
                  Navigator.of(context).pop(); // Volver a la lista de cotizaciones
                },
                icon: Icon(Icons.check_circle, size: 20),
                label: Text('Entendido'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoRetroalimentacion(int index) {
    final TextEditingController retroalimentacionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.edit_note, color: Colors.orange[800], size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Solicitud de Cambios',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'El cliente solicita modificaciones',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Describe los cambios solicitados:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: retroalimentacionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Ejemplo: Cliente solicita cambio en el sistema de suspensión y reducción en el precio...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.orange[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.orange[600]!, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.orange[50],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () {
                if (retroalimentacionController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                  _procesarSolicitudCambios(index, retroalimentacionController.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
              ),
              child: Text('Registrar Cambios'),
            ),
          ],
        );
      },
    );
  }

  void _procesarSolicitudCambios(int index, String retroalimentacion) {
    setState(() {
      etapas[index]['completado'] = false; // No se completa, necesita modificaciones
      etapas[index]['retroalimentacion'] = retroalimentacion;
      etapas[index]['requiereCambios'] = true;
      etapas[index]['fecha'] = DateFormat('yyyy-MM-dd').format(DateTime.now());
    });
    
    _guardarCambios();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.edit_note, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text('Cambios registrados. Se requieren modificaciones a la cotización.'),
            ),
          ],
        ),
        backgroundColor: Colors.orange[600],
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Ver',
          textColor: Colors.white,
          onPressed: () {
            _mostrarRetroalimentacionCompleta(retroalimentacion);
          },
        ),
      ),
    );
  }

  void _procesarRechazo(int index) {
    _mostrarDialogoMotivoRechazo(index);
  }

  void _mostrarDialogoMotivoRechazo(int index) {
    final TextEditingController motivoController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.red[800], size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Motivo del Rechazo',
                  style: TextStyle(
                    color: Colors.red[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red[700], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'El cliente rechazó la cotización',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Describe el motivo del rechazo:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: motivoController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Ejemplo: Precio muy alto, no cumple con los requerimientos técnicos, cliente encontró mejor opción...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red[600]!, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.red[50],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () {
                if (motivoController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                  _confirmarRechazoConMotivo(index, motivoController.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: Text('Confirmar Rechazo'),
            ),
          ],
        );
      },
    );
  }

  void _confirmarRechazoConMotivo(int index, String motivo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.red[700], size: 28),
              SizedBox(width: 12),
              Text('Confirmar Rechazo', style: TextStyle(color: Colors.red[700])),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Estás seguro de que quieres marcar esta cotización como rechazada?',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Motivo del rechazo:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      motivo,
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Esta acción marcará la cotización como cancelada.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  estadoEspecial = 'cancelada';
                  etapas[index]['rechazado'] = true;
                  etapas[index]['motivoRechazo'] = motivo;
                  etapas[index]['fecha'] = DateFormat('yyyy-MM-dd').format(DateTime.now());
                });
                _guardarCambios();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.cancel, color: Colors.white),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text('Cotización marcada como rechazada'),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red[600],
                    duration: Duration(seconds: 3),
                    action: SnackBarAction(
                      label: 'Ver motivo',
                      textColor: Colors.white,
                      onPressed: () {
                        _mostrarMotivoRechazoCompleto(motivo);
                      },
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
              child: Text('Confirmar Rechazo', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _mostrarMotivoRechazoCompleto(String motivo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.cancel, color: Colors.red[700], size: 24),
              SizedBox(width: 8),
              Text(
                'Motivo del Rechazo',
                style: TextStyle(color: Colors.red[700]),
              ),
            ],
          ),
          // ignore: sized_box_for_whitespace
          content: Container(
            width: double.maxFinite,
            child: Text(motivo),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarRetroalimentacionCompleta(String retroalimentacion) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Retroalimentación del Cliente'),
          // ignore: sized_box_for_whitespace
          content: Container(
            width: double.maxFinite,
            child: Text(retroalimentacion),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}