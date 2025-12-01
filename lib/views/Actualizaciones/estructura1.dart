import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transtools/api/quote_controller.dart';
import 'package:transtools/api/login_controller.dart';
import 'package:transtools/models/cotizacion.dart';
import 'package:transtools/models/usuario.dart';
import 'package:loading_indicator/loading_indicator.dart';

class Seccion1 extends StatefulWidget {
  // ignore: use_super_parameters
  const Seccion1({Key? key}) : super(key: key);
  @override
  State<Seccion1> createState() => _Seccion1();
}

class _Seccion1 extends State<Seccion1> {
  Usuario? _usuario;
  Cotizacion? _cotizacionActual;
  var cotizacionCtrl = TextEditingController();
  final nombreCtrl = TextEditingController();
  final empresaCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();
  final correoCtrl = TextEditingController();
  final fechaCtrl = TextEditingController();
  final largoCtrl = TextEditingController();
  final anchoCtrl = TextEditingController();
  final altoCtrl = TextEditingController();
  String? vigenciaSeleccionada;
  List<Map<String, String>> _grupos = [];
  String? productoSeleccionado;
  String? lineaSeleccionada;
  String? ejesSeleccionados;
  List<Map<String, String>> _modelos = [];
  String? modeloSeleccionado;
  String? yearSeleccionado;

  List<Map<String, String>> _ejesDisponibles = [];

  final FocusNode nombreFocusNode = FocusNode();
  final FocusNode empresaFocusNode = FocusNode();
  final FocusNode telefonoFocusNode = FocusNode();
  final FocusNode correoFocusNode = FocusNode();

  bool nombreError = false;
  bool empresaError = false;
  bool telefonoError = false;
  bool correoError = false;

  String? nombreErrorText;
  String? empresaErrorText;
  String? telefonoErrorText;
  String? correoErrorText;

  bool vigenciaError = false;
  String? vigenciaErrorText;

  bool productoError = false;
  String? productoErrorText;

  bool lineaError = false;
  String? lineaErrorText;

  bool ejesError = false;
  String? ejesErrorText;

  // ignore: unused_field
  bool _loadingEjes = false;

  bool modeloError = false;
  String? modeloErrorText;

  bool yearError = false;
  String? yearErrorText;

  bool colorError = false;
  String? colorErrorText;
  String? colorSeleccionado;

  bool _mostroAdvertenciaFaltantes = false;

  // Clientes
  List<Map<String, String>> _clientes = [];
  Map<String, String>? _clienteSeleccionado; // guarda el map completo

  Future<void> _cargarClientes() async {
    try {
      final lista = await QuoteController.consultaClientes(
        vendedor: _usuario?.fullname,
      );
      if (!mounted) return;
      setState(() {
        _clientes = lista;
      });
    } catch (_) {
      // Silencioso por ahora; se podría mostrar snackbar
    }
  }

  Future<void> _crearNuevoClienteDialog() async {
    final nombreNuevoCtrl = TextEditingController();
    final empresaNuevaCtrl = TextEditingController();
    final telefonoNuevoCtrl = TextEditingController();
    final correoNuevoCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (context, setLocalState) {
            // ignore: no_leading_underscores_for_local_identifiers
            Future<void> _guardar() async {
              if (saving) return;
              if (formKey.currentState?.validate() != true) return;
              setLocalState(() => saving = true);
              try {
                final id = await QuoteController.crearCliente(
                  nombre: nombreNuevoCtrl.text.trim(),
                  empresa: empresaNuevaCtrl.text.trim(),
                  telefono: telefonoNuevoCtrl.text.trim(),
                  correo: correoNuevoCtrl.text.trim(),
                  vendedor: _usuario?.fullname ?? '',
                );
                if (!mounted) return;
                setState(() {
                  final nuevo = {
                    'id': id.toString(),
                    'name': nombreNuevoCtrl.text.trim(),
                    // texto6 = Empresa (compañía)
                    'texto6': empresaNuevaCtrl.text.trim(),
                    'tel_fono': telefonoNuevoCtrl.text.trim(),
                    // texto8 = Correo (email)
                    'texto8': correoNuevoCtrl.text.trim(),
                  };
                  _clientes.insert(0, nuevo);
                  _clienteSeleccionado = nuevo;
                  nombreCtrl.text = nuevo['name'] ?? '';
                  // Empresa desde texto8
                  empresaCtrl.text = nuevo['texto6'] ?? '';
                  telefonoCtrl.text = nuevo['tel_fono'] ?? '';
                  // Correo desde texto6
                  correoCtrl.text = nuevo['texto8'] ?? '';
                });
                // ignore: use_build_context_synchronously
                if (mounted) Navigator.pop(context, true);
              } catch (e) {
                if (!mounted) return;
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error creando cliente: $e')),
                );
                setLocalState(() => saving = false);
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              backgroundColor: const Color(0xFFF8F8FF),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.person_add_alt_1, color: Color(0xFF1565C0), size: 28),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Nuevo Cliente',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1565C0),
                                letterSpacing: .5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Form(
                        key: formKey,
                        child: Column(
                          children: [
                            _InputField(
                              controller: nombreNuevoCtrl,
                              label: 'Nombre Completo',
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                            ),
                            _InputField(
                              controller: empresaNuevaCtrl,
                              label: 'Empresa',
                            ),
                            _InputField(
                              controller: telefonoNuevoCtrl,
                              label: 'Teléfono (10 dígitos)',
                              keyboard: TextInputType.phone,
                              maxLength: 10,
                              validator: (v) => (v == null || v.length != 10) ? '10 dígitos' : null,
                            ),
                            _InputField(
                              controller: correoNuevoCtrl,
                              label: 'Correo',
                              keyboard: TextInputType.emailAddress,
                              validator: (v) {
                                final val = v?.trim() ?? '';
                                if (val.isEmpty) return null; // opcional
                                // Patrón clásico: user@dominio.tld (2+ letras en TLD)
                                final regex = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
                                return regex.hasMatch(val) ? null : 'Correo inválido';
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: saving
                            ? Column(
                                key: const ValueKey('saving'),
                                children: const [
                                  SizedBox(height: 6),
                                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF1565C0))),
                                  SizedBox(height: 10),
                                  Text('Guardando Cliente en Monday', style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.w600)),
                                ],
                              )
                            : Row(
                                key: const ValueKey('actions'),
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF1565C0),
                                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    child: const Text('Cancelar'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: _guardar,
                                    icon: const Icon(Icons.save_outlined, size: 18),
                                    label: const Text('Guardar'),
                                    style: ElevatedButton.styleFrom(
                                      elevation: 0,
                                      backgroundColor: const Color(0xFF1565C0),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result == true) {
      // limpiar errores si hubiera
      setState(() {
        nombreError = false; nombreErrorText = null;
        empresaError = false; empresaErrorText = null;
        telefonoError = false; telefonoErrorText = null;
        correoError = false; correoErrorText = null;
      });
    }
  }

  static const List<String> _colores = [
    'NEGRO BRILLANTE',
    'NEGRO MATE',
    'BLANCO BRILLANTE',
    'AZUL HOLANDES',
    'AZUL TIPO TEJA',
    'AMARILLO CATERPILLAR',
    'VERDE',
    'NARANJA',
    'ROJO VIPER',
    'PINTURA POR CONFIRMAR'
  ];

  static const Map<String, Color> _colorSwatches = {
    'NEGRO BRILLANTE': Colors.black,
    'NEGRO MATE': Color(0xFF222222),
    'BLANCO BRILLANTE': Colors.white,
    'AZUL HOLANDES': Color(0xFF1E3A5C),
    'AZUL TIPO TEJA': Color(0xFF3B5998),
    'AMARILLO CATERPILLAR': Color(0xFFFFD600),
    'VERDE': Color(0xFF388E3C),
    'NARANJA': Color(0xFFFF9800),
    'ROJO VIPER': Color(0xFFD32F2F),
    'PINTURA POR CONFIRMAR': Color(0xFFBDBDBD),
  };

  bool get _modeloDisponible {
    return productoSeleccionado != null &&
        lineaSeleccionada != null &&
        ejesSeleccionados != null;
  }

  @override
  void initState() {
    super.initState();
    // Cargar usuario y luego clientes para que aplique el filtro por vendedor
    Future.microtask(() async {
      await _cargarUsuario();
      await _cargarClientes();
    });
    fechaCtrl.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _cargarGruposMonday(); //llamada automática al abrir

    nombreFocusNode.addListener(() {
      if (!nombreFocusNode.hasFocus && nombreCtrl.text.trim().isEmpty) {
        setState(() {
          nombreError = true;
          nombreErrorText = 'Favor de rellenar el nombre completo';
        });
      } else if (nombreFocusNode.hasFocus) {
        setState(() {
          nombreError = false;
          nombreErrorText = null;
        });
      }
    });
    // Listeners de empresa/telefono/correo removidos porque ya no son editables ni obligatorios
  }

  @override
  void dispose() {
    nombreFocusNode.dispose();
    empresaFocusNode.dispose();
    telefonoFocusNode.dispose();
    correoFocusNode.dispose();
    super.dispose();
  }

  void _irASiguiente() {
    setState(() {
      vigenciaError = vigenciaSeleccionada == null;
      vigenciaErrorText = vigenciaError
          ? 'Favor de rellenar la vigencia'
          : null;

      productoError = productoSeleccionado == null;
      productoErrorText = productoError
          ? 'Favor de rellenar el producto'
          : null;

      lineaError = lineaSeleccionada == null;
      lineaErrorText = lineaError ? 'Favor de rellenar la línea' : null;

      ejesError = ejesSeleccionados == null;
      ejesErrorText = ejesError ? 'Favor de rellenar los ejes' : null;

      modeloError = modeloSeleccionado == null;
      modeloErrorText = modeloError ? 'Favor de rellenar el modelo' : null;

      yearError = yearSeleccionado == null;
      yearErrorText = yearError ? 'Favor de rellenar la generación' : null;

      nombreError = nombreCtrl.text.trim().isEmpty;
      nombreErrorText = nombreError
          ? 'Favor de rellenar el nombre completo'
          : null;

    // Campos empresa/telefono/correo ya no obligatorios
    });

    setState(() {
      // ...otras validaciones...
      colorError = colorSeleccionado == null;
      colorErrorText = colorError ? 'Favor de seleccionar el color' : null;

    });

    if (colorError) {
      mostrarAlertaError(
        context,
        'Por favor llena todos los campos obligatorios',
      );
      return;
    }

    if (vigenciaError ||
        productoError ||
        lineaError ||
        ejesError ||
        modeloError ||
        yearError ||
        cotizacionCtrl.text.isEmpty ||
        fechaCtrl.text.isEmpty ||
  nombreCtrl.text.isEmpty) {
      mostrarAlertaError(
        context,
        'Por favor llena todos los campos obligatorios',
      );
      return;
    }

    // Ya no se valida celular o correo obligatoriamente
    {
      final modeloSeleccionadoMap = _modelos.firstWhere(
        (modelo) => modelo['value'] == modeloSeleccionado,
      );

      final modeloSeleccionadoText = modeloSeleccionadoMap['text']!;
      final modeloSeleccionadoValue = modeloSeleccionadoMap['value']!;
      final productoText = _grupos.firstWhere(
        (producto) => producto['value'] == productoSeleccionado,
      )['text']!;
      final configuracionProducto =
          '$productoText, Linea: ${lineaSeleccionada ?? ""}, ${ejesSeleccionados ?? ""} Ejes, Modelo: $modeloSeleccionadoText, Generación: ${yearSeleccionado ?? ""}';
      // Si ya existe y el modelo NO cambió, usa el mismo objeto
      if (_cotizacionActual != null &&
          _cotizacionActual!.modelo == modeloSeleccionadoText) {
        Navigator.pushNamed(
          context,
          '/seccion2',
          arguments: {
            'cotizacion': _cotizacionActual!,
            'modeloNombre': modeloSeleccionadoText,
            'modeloValue': modeloSeleccionadoValue,
            'configuracionProducto': configuracionProducto.trim(),
          },
        );
        return;
      }

      // Si es la primera vez o cambió el modelo, crea uno nuevo
      final cotizacion = Cotizacion(
        folioCotizacion: cotizacionCtrl.text.trim(),
        fechaCotizacion: DateFormat('dd/MM/yyyy').parse(fechaCtrl.text),
        fechaVigencia: _calcularFechaVigenciaDesdeSeleccion(
          vigenciaSeleccionada!,
        ),
        cliente: nombreCtrl.text.trim(),
        empresa: empresaCtrl.text.trim(),
        telefono: telefonoCtrl.text.trim(),
        correo: correoCtrl.text.trim(),
        producto: productoText,
        linea: lineaSeleccionada ?? '',
        numeroEjes: int.tryParse(ejesSeleccionados ?? '0') ?? 0,
        modelo: modeloSeleccionadoText,
        color: colorSeleccionado ?? '',
        
        generacion: int.tryParse(yearSeleccionado ?? '0') ?? 0,
      );
      _cotizacionActual = cotizacion;

      Navigator.pushNamed(
        context,
        '/seccion2',
        arguments: {
          'cotizacion': cotizacion,
          'modeloNombre': modeloSeleccionadoText,
          'modeloValue': modeloSeleccionadoValue,
          'configuracionProducto': configuracionProducto.trim(),
        },
      );
    }
  }

  DateTime _calcularFechaVigenciaDesdeSeleccion(String seleccion) {
    // Buscar el primer número en el string (ej. "7 días" → 7)
    final match = RegExp(r'\d+').firstMatch(seleccion);
    if (match != null) {
      final dias = int.parse(match.group(0)!);
      return DateTime.now().add(Duration(days: dias));
    }
    // Si no encuentra número, por defecto agrega 7 días
    return DateTime.now().add(const Duration(days: 7));
  }

  void mostrarAlertaError(BuildContext context, String mensaje) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text(mensaje),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              textStyle: const TextStyle(color: CupertinoColors.systemBlue),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Aceptar',
                style: TextStyle(color: Color(0xFF1565C0)),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _verificarYConsultarGrupo() {
    if (productoSeleccionado != null &&
        lineaSeleccionada != null &&
        ejesSeleccionados != null) {
      _cargarModelosPorGrupo(
        productoSeleccionado,
        lineaSeleccionada,
        ejesSeleccionados,
      );
    }
  }

  Future<void> _cargarUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('usuario');
    if (jsonString != null) {
      _usuario = Usuario.fromJson(jsonString);
      final mesActual = DateTime.now().month.toString().padLeft(2, '0');
      final fullname = _usuario!.fullname;
      final consecutivo = await QuoteController.obtenerConsecutivoCotizacion(
        fullname,
        mesActual,
      );
      final consecutivoStr = (consecutivo + 1).toString().padLeft(4, '0');
      setState(() {
        cotizacionCtrl.text =
            'COT-${_usuario!.initials}$mesActual-$consecutivoStr';
      });
    }
  }

Future<void> _cargarGruposMonday() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('grupos');

  // ignore: use_build_context_synchronously
  final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

  if (args == null) {
    setState(() {
      nombreCtrl.clear();
      empresaCtrl.clear();
      telefonoCtrl.clear();
      correoCtrl.clear();
      fechaCtrl.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
      vigenciaSeleccionada = null;
      productoSeleccionado = null;
      lineaSeleccionada = null;
      ejesSeleccionados = null;
      modeloSeleccionado = null;
      yearSeleccionado = null;
      colorSeleccionado = null;
      _modelos = [];
    });
  }

  await _cargarUsuario();

  // ...resto de la función igual...

    final gruposCacheString = prefs.getString('grupos');

    if (gruposCacheString != null) {
      // Parsear cache y mapear claves a 'value' y 'text'
      final List<dynamic> gruposJson = jsonDecode(gruposCacheString);
      // Aplicar filtrado por rol usando LoginController
      final loginController = LoginController();
      final gruposFiltradosRaw = await loginController.filterGruposByRole(gruposJson);
      setState(() {
        _grupos = gruposFiltradosRaw.map<Map<String, String>>((g) {
          return {
            'value': g['value']?.toString() ?? '',
            'text': g['text']?.toString() ?? '',
          };
        }).toList();
      });
    } else {
      try {
        const boardId = 4863963204;
        final gruposApi = await QuoteController.obtenerGrupos(boardId);
        await prefs.setString('grupos', jsonEncode(gruposApi));

        // Filtrar grupos según rol
        final loginController = LoginController();
        final gruposFiltradosRaw = await loginController.filterGruposByRole(gruposApi);

      setState(() {
        _grupos = gruposFiltradosRaw.map<Map<String, String>>((g) {
          return {
            'value': g['value']?.toString() ?? '',
            'text': g['text']?.toString() ?? '',
          };
        }).toList();
      });
      // ignore: unused_local_variable, use_build_context_synchronously
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      // Relleno automático
    } catch (e) {
      // Manejar error
    }
  }

    if (args != null) {
      final grupo = args['grupo'];
      final producto = args['producto'];

      if (grupo != null) {
        final existeGrupo = _grupos.any((g) => g['value'] == grupo['value']);
        if (existeGrupo) {
          setState(() {
            productoSeleccionado = grupo['value'];
          });
        }
      }
      if (producto != null) {
        setState(() {
          lineaSeleccionada = producto['linea'];
          ejesSeleccionados = producto['ejes'];
        });
      }
      
      // Si tienes que cargar ejes compatibles, hazlo aquí:
      if (productoSeleccionado != null && lineaSeleccionada != null) {
        QuoteController.obtenerEjesCompatibles(productoSeleccionado!, lineaSeleccionada!).then((ejes) {
          setState(() {
            _ejesDisponibles = ejes;
          });
        });
      }
      // Si necesitas cargar modelos, llama a _verificarYConsultarGrupo();
      _verificarYConsultarGrupo();
    }
  }

  Future<void> _cargarModelosPorGrupo(
    String? producto,
    String? linea,
    String? ejes,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 10),
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: LoadingIndicator(
                    indicatorType: Indicator.ballRotateChase,
                    colors: [Color(0xFF1565C0)],
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Cargando Modelos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final modelos = await QuoteController.obtenerModelosPorGrupo(
        producto!,
        linea!,
        ejes!,
      );
      if (!mounted) return;

      setState(() {
        _modelos =
            modelos; // Asegúrate de tener esta lista definida en tu State
      });

      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
if (args != null && args['producto'] != null) {
  final modeloValue = args['producto']['text'];
  final existeModelo = _modelos.any((m) => m['text'] == modeloValue);
  if (existeModelo) {
    setState(() {
      modeloSeleccionado = _modelos.firstWhere((m) => m['text'] == modeloValue)['value'];
    });
  }
}
    } catch (e) {
      if (!mounted) return;
      mostrarAlertaError(context, 'Error al cargar modelos');
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }



  @override
  Widget build(BuildContext context) {

    WidgetsBinding.instance.addPostFrameCallback((_) {
  if (!_mostroAdvertenciaFaltantes &&
      productoSeleccionado != null &&
      lineaSeleccionada != null &&
      ejesSeleccionados != null &&
      modeloSeleccionado != null &&
      (nombreCtrl.text.isEmpty ||
       empresaCtrl.text.isEmpty ||
       telefonoCtrl.text.isEmpty ||
       correoCtrl.text.isEmpty ||
       vigenciaSeleccionada == null ||
       yearSeleccionado == null ||
       colorSeleccionado == null)) {
    _mostroAdvertenciaFaltantes = true;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFF1565C0), size: 32),
            const SizedBox(width: 10),
            const Text('Datos faltantes', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Por favor, rellena los datos faltantes de la sección 1 para continuar.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Color(0xFF1565C0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
});
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
  backgroundColor: Color(0xFF1565C0),
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text(
            'Datos Iniciales',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Barra de progreso
            const LinearProgressIndicator(
              value: 1 / 3, //
              backgroundColor: Color.fromARGB(255, 0, 0, 0),
              valueColor: AlwaysStoppedAnimation<Color>(
                Color.fromARGB(255, 210, 198, 59),
              ),
              minHeight: 6,
            ),
            const SizedBox(height: 8),
            const Text(
              'Paso 1 de 4',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // El contenido scrollable
            Expanded(
              child: RefreshIndicator(
                color: Color(0xFF1565C0),
                onRefresh: _cargarGruposMonday,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSection(
                      title: 'Información Inicial',
                      children: [
                        _CustomTextField(
                          controller: cotizacionCtrl,
                          hint: 'Número de Cotización',
                          enabled: false,
                          keyboardType: TextInputType.text,
                          inputFormatters: const [],
                        ),
                        _CustomTextField(
                          controller: fechaCtrl,
                          hint: 'Fecha de cotización',
                          enabled: false,
                          keyboardType: TextInputType.text,
                          inputFormatters: const [],
                        ),
                      ],
                    ),
                    // --- Aquí va el panel separado de vigencia ---
                    _buildSection(
                      title: 'Vigencia',
                      children: [
                        _VigenciaDropdown(
                          valorSeleccionado: vigenciaSeleccionada,
                          onChanged: (value) {
                            setState(() {
                              vigenciaSeleccionada = value;
                              vigenciaError = false;
                              vigenciaErrorText = null;
                            });
                          },
                          error: vigenciaError,
                          errorText: vigenciaErrorText,
                        ),
                      ],
                    ),
                    _buildSection(
                      title: 'Información del Cliente',
                      children: [
                        _ClienteDropdown(
                          clientes: _clientes,
                          valueId: _clienteSeleccionado?['id'],
                          error: nombreError,
                          errorText: nombreErrorText,
                          onChanged: (cliente) {
                            setState(() {
                              _clienteSeleccionado = cliente;
                              if (cliente != null) {
                                nombreCtrl.text = cliente['name'] ?? '';
                                // Empresa proviene de texto8
                                empresaCtrl.text = cliente['texto6'] ?? '';
                                telefonoCtrl.text = cliente['tel_fono'] ?? '';
                                // Correo proviene de texto6
                                correoCtrl.text = cliente['texto8'] ?? '';
                                nombreError = false; nombreErrorText = null;
                                empresaError = false; empresaErrorText = null;
                                telefonoError = false; telefonoErrorText = null;
                                correoError = false; correoErrorText = null;
                              } else {
                                nombreCtrl.clear();
                                empresaCtrl.clear();
                                telefonoCtrl.clear();
                                correoCtrl.clear();
                              }
                            });
                          },
                          onCreateRequested: _crearNuevoClienteDialog,
                        ),
                        _CustomTextField(
                          controller: empresaCtrl,
                          hint: 'Empresa',
                          keyboardType: TextInputType.text,
                          inputFormatters: const [],
                          enabled: false,
                          focusNode: empresaFocusNode,
                          error: false,
                          errorText: null,
                        ),
                        _CustomTextField(
                          controller: telefonoCtrl,
                          hint: 'Número de Celular',
                          keyboardType: TextInputType.phone,
                          inputFormatters: const [],
                          enabled: false,
                          focusNode: telefonoFocusNode,
                          error: false,
                          errorText: null,
                        ),
                        _CustomTextField(
                          controller: correoCtrl,
                          hint: 'Correo Electronico',
                          keyboardType: TextInputType.emailAddress,
                          inputFormatters: const [],
                          enabled: false,
                          focusNode: correoFocusNode,
                          error: false,
                          errorText: null,
                        ),
                      ],
                    ),
                    _buildSection(
                      title: 'Producto',
                      children: [
                        _ProductoDropdown(
                          productos: _grupos,
                          value: productoSeleccionado,
                          onChanged: (v) => setState(() {
                            productoSeleccionado = v;
                            productoError = false;
                            productoErrorText = null;
                            modeloSeleccionado = null;
                            _verificarYConsultarGrupo();
                          }),
                          error: productoError,
                          errorText: productoErrorText,
                        ),
                      ],
                    ),
                    _buildSection(
                      title: 'Linea',
                      children: [
                        _LineaDropdown(
                          value: lineaSeleccionada,
                          onChanged: (v) async {
                            setState(() {
                              lineaSeleccionada = v;
                              lineaError = false;
                              lineaErrorText = null;
                              modeloSeleccionado = null;
                              ejesSeleccionados = null;
                              _ejesDisponibles = [];
                            });
                            if (productoSeleccionado != null && v != null) {
                              setState(() => _loadingEjes = true);
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext dialogContext) {
                                  return Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: const Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 60,
                                            height: 60,
                        child: CircularProgressIndicator(
                          color: Color(0xFF1565C0),
                                              strokeWidth: 4,
                                            ),
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'Cargando ejes',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1565C0),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                              final ejes =
                                  await QuoteController.obtenerEjesCompatibles(
                                    productoSeleccionado!,
                                    v,
                                  );
                              if (mounted) {
                                Navigator.of(
                                  // ignore: use_build_context_synchronously
                                  context,
                                  rootNavigator: true,
                                ).pop();
                                setState(() {
                                  _ejesDisponibles = ejes;
                                  _loadingEjes = false;
                                });
                              }
                            }
                            _verificarYConsultarGrupo();
                          },
                          error: lineaError,
                          errorText: lineaErrorText,
                        ),
                      ],
                    ),
                    _buildSection(
                      title: 'Ejes',
                      children: [
                        NumeroEjesDropdown(
                          value: ejesSeleccionados,
                          opciones: _ejesDisponibles,
                          onChanged: (v) => setState(() {
                            ejesSeleccionados = v;
                            ejesError = false;
                            ejesErrorText = null;
                            modeloSeleccionado = null;
                            _verificarYConsultarGrupo();
                          }),
                          error: ejesError,
                          errorText: ejesErrorText,
                        ),
                      ],
                    ),
                    // Aquí se determina si el modelo está disponible
                    _buildSection(
                      title: 'Modelo/Gama',
                      children: [
                        _ModeloDropdown(
                          value: modeloSeleccionado,
                          enabled: _modeloDisponible && _modelos.isNotEmpty,
                          modelos: _modelos,
                          onChanged: (v) => setState(() {
                            modeloSeleccionado = v;
                            modeloError = false;
                            modeloErrorText = null;
                          }),
                          error: modeloError,
                          errorText: modeloErrorText,
                        ),
                        if (_modeloDisponible && _modelos.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Center(
                              child: Text(
                                'Sin modelos disponibles',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    _buildSection(
                      title: 'Color',
                      children: [
                        // Dropdown de color
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 240, 240, 240),
                            borderRadius: BorderRadius.circular(29),
                            border: Border.all(
                              color: colorError
                                  ? Colors.red
                                  : Colors.grey[300]!,
                              width: 1.5,
                            ),
                          ),

                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: colorSeleccionado,
                              hint: Text(
                                'Selecciona el color',
                                style: TextStyle(
                                  color: colorError
                                      ? Colors.red
                                      : const Color.fromARGB(255, 0, 0, 0),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              icon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (colorSeleccionado != null)
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          colorSeleccionado = null;
                                        });
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.only(right: 4),
                                        child: Icon(
                                          Icons.clear,
                                          color: Colors.grey,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    color: Color(0xFF565656),
                                    size: 28,
                                  ),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              menuMaxHeight: 210,
                              dropdownColor: Colors.white,
                              onChanged: (value) {
                                setState(() {
                                  colorSeleccionado = value;
                                  colorError = false;
                                  colorErrorText = null;
                                  // También puedes limpiar el error de marca si lo deseas
                                });
                              },
                              items: _colores.map((color) {
                                return DropdownMenuItem<String>(
                                  value: color,
                                  child: Text(color),
                                );
                              }).toList(),
                            ),
                          ),
                        ),                                          
                        // Muestra la selección final y la muestra de color abajo a la derecha
                        if (colorSeleccionado != null)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Color elegido:'
                                    ' $colorSeleccionado',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1565C0),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(
                                  left: 12,
                                  right: 4,
                                  top: 8,
                                  bottom: 8,
                                ),
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color:
                                      _colorSwatches[colorSeleccionado] ??
                                      Colors.transparent,
                                  border: Border.all(
                                    color: Colors.grey[400]!,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    _buildSection(
                      title: 'Generación',
                      children: [
                        _YearPickerField(
                          initialYear:
                              yearSeleccionado, // yearSeleccionado debe ser String? (nullable)
                          onYearSelected: (year) {
                            setState(() {
                              yearSeleccionado = year; // Aquí puede ser null
                            });
                          },
                          error: yearError,
                          errorText: yearErrorText,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _NavigationButton(
                          label: 'Atras',
                          onPressed: () {
                            Navigator.pushNamed(context, '/dashboard');
                          },
                        ),
                        _NavigationButton(
                          label: 'Siguiente',
                          onPressed: _irASiguiente,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _ClienteDropdown extends StatefulWidget {
  final List<Map<String, String>> clientes;
  final String? valueId; // id seleccionado
  final bool error;
  final String? errorText;
  final void Function(Map<String, String>? cliente) onChanged;
  final VoidCallback? onCreateRequested;

  const _ClienteDropdown({
    required this.clientes,
    required this.valueId,
    required this.onChanged,
    this.onCreateRequested,
    this.error = false,
    this.errorText,
  });

  @override
  State<_ClienteDropdown> createState() => _ClienteDropdownState();
}

class _ClienteDropdownState extends State<_ClienteDropdown> {
  late List<Map<String, String>> _filteredClientes;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _filteredClientes = widget.clientes;
    final seleccionado = widget.clientes.firstWhere(
      (c) => c['id'] == widget.valueId,
      orElse: () => {'name': '', 'id': ''},
    );
    _controller.text = seleccionado['name'] ?? '';
    _focusNode.addListener(_handleFocusChange);
    _controller.addListener(_handleTextChange);
  }

  @override
  void didUpdateWidget(covariant _ClienteDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clientes != widget.clientes) {
      _filteredClientes = widget.clientes;
    }
    if (oldWidget.valueId != widget.valueId) {
      final seleccionado = widget.clientes.firstWhere(
        (c) => c['id'] == widget.valueId,
        orElse: () => {'name': '', 'id': ''},
      );
      _controller.text = seleccionado['name'] ?? '';
    }
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _handleTextChange() {
    final query = _controller.text.toLowerCase();
    setState(() {
      _filteredClientes = widget.clientes.where((c) {
        final name = c['name']?.toLowerCase() ?? '';
        final empresa = c['texto8']?.toLowerCase() ?? '';
        return name.contains(query) || empresa.contains(query);
      }).toList();
    });
    _overlayEntry?.markNeedsBuild();
  }

  void _showOverlay() {
    _removeOverlay();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null || !mounted) return;
      _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          width: renderBox.size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, renderBox.size.height + 5),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.1 * 255).round()),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                constraints: const BoxConstraints(maxHeight: 240),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: (widget.clientes.isEmpty)
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: Center(
                                child: Text(
                                  'Sin clientes registrados. Favor de registrar.',
                                  style: TextStyle(color: Colors.grey[600]),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : _filteredClientes.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Center(
                                    child: Text(
                                      'No se encontraron coincidencias',
                                      style: TextStyle(color: Colors.grey[600]),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: _filteredClientes.length,
                              itemBuilder: (context, index) {
                                final option = _filteredClientes[index];
                                return InkWell(
                                  onTap: () {
                                    _controller.text = option['name'] ?? '';
                                    widget.onChanged(option);
                                    _focusNode.unfocus();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _controller.text == option['name']
                                          ? Theme.of(context)
                                              .primaryColor
                                              .withAlpha((0.1 * 255).round())
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          option['name'] ?? '',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: _controller.text == option['name']
                                                ? Theme.of(context).primaryColor
                                                : Colors.black,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if ((option['texto8'] ?? '').isNotEmpty)
                                          Text(
                                            option['texto8']!,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    if (widget.onCreateRequested != null)
                      InkWell(
                        onTap: () {
                          _focusNode.unfocus();
                          widget.onCreateRequested?.call();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: Colors.grey.shade300)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.add, color: Color(0xFF1565C0)),
                              SizedBox(width: 8),
                              Text('Crear nuevo cliente', style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      if (mounted) {
        Overlay.of(context).insert(_overlayEntry!);
      }
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _controller.removeListener(_handleTextChange);
    _focusNode.dispose();
    _controller.dispose();
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (_focusNode.hasFocus) {
                _focusNode.unfocus();
              } else {
                _focusNode.requestFocus();
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 240, 240, 240),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: widget.error
                      ? Colors.red
                      : (_focusNode.hasFocus
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300]!),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'Selecciona el cliente',
                        hintStyle: TextStyle(
                          color: widget.error ? Colors.red : Colors.black,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        suffixIcon: _controller.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                color: Colors.grey,
                                onPressed: () {
                                  _controller.clear();
                                  widget.onChanged(null);
                                  setState(() {
                                    _filteredClientes = widget.clientes;
                                  });
                                  _focusNode.requestFocus();
                                },
                              )
                            : null,
                      ),
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: const Color.fromARGB(255, 86, 86, 86),
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.error && widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 2),
            child: Text(
              widget.errorText!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
      ],
    );
  }
}

class _VigenciaDropdown extends StatelessWidget {
  final String? valorSeleccionado;
  final void Function(String?) onChanged;
  final bool error;
  final String? errorText;

  static const List<Map<String, String>> _opciones = [
    {'value': '1 día', 'text': '1 día'},
    {'value': '7 días', 'text': '7 días'},
    {'value': '15 días', 'text': '15 días'},
    {'value': '30 días', 'text': '30 días'},
  ];

  // ignore: use_super_parameters
  const _VigenciaDropdown({
    Key? key,
    required this.valorSeleccionado,
    required this.onChanged,
    this.error = false,
    this.errorText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 240, 240, 240),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: error ? Colors.red : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: valorSeleccionado,
              hint: Text(
                'Selecciona la vigencia',
                style: TextStyle(
                  color: error ? Colors.red : Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (valorSeleccionado != null)
                    GestureDetector(
                      onTap: () => onChanged(null),
                      child: const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.clear, color: Colors.grey, size: 22),
                      ),
                    ),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF565656),
                    size: 28,
                  ),
                ],
              ),
              dropdownColor: Colors.white,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
              borderRadius: BorderRadius.circular(16),
              onChanged: onChanged,
              items: _opciones.map((opcion) {
                return DropdownMenuItem<String>(
                  value: opcion['value'],
                  child: Text(opcion['text']!),
                );
              }).toList(),
            ),
          ),
        ),
        if (error && errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 2),
            child: Text(
              errorText!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
      ],
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool error;
  final String? errorText;

  const _CustomTextField({
    required this.hint,
    required this.controller,
    this.enabled = true,
    this.keyboardType,
    this.inputFormatters,
    this.focusNode,
    this.error = false,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: hint,
          enabled: enabled,
          filled: true,
          fillColor: const Color.fromARGB(255, 237, 237, 237),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: error ? Colors.red : const Color(0xFF1565C0),
              width: 2,
            ),
          ),
          floatingLabelStyle: TextStyle(
            color: error ? Colors.red : const Color(0xFF1565C0),
            fontWeight: FontWeight.w600,
          ),
          errorText: error ? errorText : null,
        ),
      ),
    );
  }
}

class _ProductoDropdown extends StatefulWidget {
  final List<Map<String, String>> productos;
  final String? value;
  final void Function(String?) onChanged;
  final bool enabled;
  final bool error;
  final String? errorText;

  const _ProductoDropdown({
    required this.productos,
    required this.value,
    required this.onChanged,
    // ignore: unused_element_parameter
    this.enabled = true,
    this.error = false,
    this.errorText,
  });

  @override
  State<_ProductoDropdown> createState() => _ProductoDropdownState();
}

class _ProductoDropdownState extends State<_ProductoDropdown> {
  late List<Map<String, String>> _filteredProductos;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _filteredProductos = widget.productos;

    // Si hay valor seleccionado, buscar el texto para mostrarlo en el TextField
    final seleccionado = widget.productos.firstWhere(
      (p) => p['value'] == widget.value,
      orElse: () => {'text': '', 'value': ''},
    );
    _controller.text = seleccionado['text'] ?? '';

    _focusNode.addListener(_handleFocusChange);
    _controller.addListener(_handleTextChange);
  }

  @override
  void didUpdateWidget(covariant _ProductoDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si la lista de productos cambia, actualizar filtro
    if (oldWidget.productos != widget.productos) {
      _filteredProductos = widget.productos;
    }

    // Si cambia el value, actualizar texto
    if (oldWidget.value != widget.value) {
      final seleccionado = widget.productos.firstWhere(
        (p) => p['value'] == widget.value,
        orElse: () => {'text': '', 'value': ''},
      );
      _controller.text = seleccionado['text'] ?? '';
    }
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _handleTextChange() {
    final query = _controller.text.toLowerCase();
    setState(() {
      _filteredProductos = widget.productos.where((producto) {
        final text = producto['text']?.toLowerCase() ?? '';
        return text.contains(query);
      }).toList();
    });

    _overlayEntry?.markNeedsBuild();
  }

  void _showOverlay() {
    _removeOverlay();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null || !mounted) return;

      _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          width: renderBox.size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, renderBox.size.height + 5),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.1 * 255).round()),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: _filteredProductos.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No se encontraron coincidencias',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: _filteredProductos.length,
                        itemBuilder: (context, index) {
                          final option = _filteredProductos[index];
                          return InkWell(
                            onTap: () {
                              _controller.text = option['text'] ?? '';
                              widget.onChanged(option['value']);
                              _focusNode.unfocus();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: _controller.text == option['text']
                                    ? Theme.of(context).primaryColor.withAlpha(
                                        (0.1 * 255).round(),
                                      )
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                option['text'] ?? '',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _controller.text == option['text']
                                      ? Theme.of(context).primaryColor
                                      : Colors.black,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ),
      );

      if (mounted) {
        Overlay.of(context).insert(_overlayEntry!);
      }
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _controller.removeListener(_handleTextChange);
    _focusNode.dispose();
    _controller.dispose();
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (_focusNode.hasFocus) {
                _focusNode.unfocus();
              } else {
                _focusNode.requestFocus();
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 240, 240, 240),
                borderRadius: BorderRadius.circular(29),
                border: Border.all(
                  color: widget.error
                      ? Colors.red
                      : (_focusNode.hasFocus
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300]!),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      decoration: InputDecoration(
                        hintText: 'Selecciona un producto',
                        // enabled: widget.enabled,
                        hintStyle: TextStyle(
                          color: widget.error ? Colors.red : Colors.black,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        suffixIcon: _controller.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                color: Colors.grey,
                                onPressed: () {
                                  _controller.clear();
                                  widget.onChanged(null);
                                  setState(() {
                                    _filteredProductos = widget.productos;
                                  });
                                  _focusNode.requestFocus();
                                },
                              )
                            : null,
                      ),
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                  Opacity(
                    opacity: widget.enabled ? 1.0 : 0.5,
                    child: Icon(
                      Icons.arrow_drop_down,
                      color: const Color.fromARGB(255, 86, 86, 86),
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.error && widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 2),
            child: Text(
              widget.errorText!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
      ],
    );
  }
}

class _LineaDropdown extends StatefulWidget {
  final String? value;
  final void Function(String?) onChanged;
  final bool error;
  final String? errorText;

  const _LineaDropdown({
    required this.value,
    required this.onChanged,
    this.error = false,
    this.errorText,
  });

  @override
  State<_LineaDropdown> createState() => _LineaDropdownState();
}

class _LineaDropdownState extends State<_LineaDropdown> {
  static const List<String> _lineas = [
    'Titanium Fleet Max',
    'Titanium AMForce',
    'Titanium Elite',
    'Titanium HRP',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 240, 240, 240),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: widget.error ? Colors.red : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: widget.value,
              hint: Text(
                'Selecciona la línea',
                style: TextStyle(
                  fontSize: 16,
                  color: widget.error ? Colors.red : Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onChanged: widget.onChanged,
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(16),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.value != null)
                    GestureDetector(
                      onTap: () => widget.onChanged(null),
                      child: const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.clear, color: Colors.grey, size: 22),
                      ),
                    ),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF565656),
                    size: 28,
                  ),
                ],
              ),
              items: _lineas
                  .map(
                    (option) => DropdownMenuItem(
                      value: option,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(option, textAlign: TextAlign.left),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        if (widget.error && widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 2),
            child: Text(
              widget.errorText!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
      ],
    );
  }
}

class NumeroEjesDropdown extends StatelessWidget {
  final String? value;
  final void Function(String?) onChanged;
  final List<Map<String, String>> opciones;
  final bool error;
  final String? errorText;

  const NumeroEjesDropdown({
    Key? key,
    required this.value,
    required this.onChanged,
    required this.opciones,
    this.error = false,
    this.errorText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 240, 240, 240),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: error ? Colors.red : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: opciones.any((item) => item['value'] == value)
                  ? value
                  : null,
              hint: Text(
                'Selecciona el número de ejes',
                style: TextStyle(
                  color: error ? Colors.red : Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (value != null)
                    GestureDetector(
                      onTap: () => onChanged(null),
                      child: const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.clear, color: Colors.grey, size: 22),
                      ),
                    ),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF565656),
                    size: 28,
                  ),
                ],
              ),
              dropdownColor: Colors.white,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
              borderRadius: BorderRadius.circular(16),
              onChanged: onChanged,
              items: opciones.map((opcion) {
                return DropdownMenuItem<String>(
                  value: opcion['value'],
                  child: Text(opcion['text']!),
                );
              }).toList(),
            ),
          ),
        ),
        if (error && errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 2),
            child: Text(
              errorText!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
      ],
    );
  }
}

class _ModeloDropdown extends StatefulWidget {
  final String? value;
  final void Function(String?)? onChanged;
  final bool enabled;
  final List<Map<String, String>> modelos;
  final bool error;
  final String? errorText;

  const _ModeloDropdown({
    required this.value,
    required this.onChanged,
    required this.modelos,
    this.enabled = true,
    this.error = false,
    this.errorText,
  });

  @override
  State<_ModeloDropdown> createState() => _ModeloDropdownState();
}

class _ModeloDropdownState extends State<_ModeloDropdown> {
  late List<Map<String, String>> _filteredModelos;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _filteredModelos = widget.modelos;
    final seleccionado = widget.modelos.firstWhere(
      (m) => m['value'] == widget.value,
      orElse: () => {'text': '', 'value': ''},
    );
    _controller.text = seleccionado['text'] ?? '';
    _focusNode.addListener(_handleFocusChange);
    _controller.addListener(_handleTextChange);
  }

  @override
  void didUpdateWidget(covariant _ModeloDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.modelos != widget.modelos) {
      _filteredModelos = widget.modelos;
    }
    if (oldWidget.value != widget.value) {
      final seleccionado = widget.modelos.firstWhere(
        (m) => m['value'] == widget.value,
        orElse: () => {'text': '', 'value': ''},
      );
      _controller.text = seleccionado['text'] ?? '';
    }
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus && widget.enabled) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _handleTextChange() {
    final query = _controller.text.toLowerCase();
    setState(() {
      _filteredModelos = widget.modelos.where((modelo) {
        final text = modelo['text']?.toLowerCase() ?? '';
        return text.contains(query);
      }).toList();
    });
    _overlayEntry?.markNeedsBuild();
  }

  void _showOverlay() {
    _removeOverlay();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null || !mounted) return;
      _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          width: renderBox.size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, renderBox.size.height + 5),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.1 * 255).round()),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: _filteredModelos.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No se encontraron coincidencias',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: _filteredModelos.length,
                        itemBuilder: (context, index) {
                          final option = _filteredModelos[index];
                          return InkWell(
                            onTap: () {
                              _controller.text = option['text'] ?? '';
                              widget.onChanged?.call(option['value']);
                              _focusNode.unfocus();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: _controller.text == option['text']
                                    ? Theme.of(context).primaryColor.withAlpha(
                                        (0.1 * 255).round(),
                                      )
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                option['text'] ?? '',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _controller.text == option['text']
                                      ? Theme.of(context).primaryColor
                                      : Colors.black,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ),
      );
      if (mounted) {
        Overlay.of(context).insert(_overlayEntry!);
      }
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _controller.removeListener(_handleTextChange);
    _focusNode.dispose();
    _controller.dispose();
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (_focusNode.hasFocus) {
                _focusNode.unfocus();
              } else {
                _focusNode.requestFocus();
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 240, 240, 240),
                borderRadius: BorderRadius.circular(29),
                border: Border.all(
                  color: widget.error
                      ? Colors.red
                      : (_focusNode.hasFocus
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300]!),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      decoration: InputDecoration(
                        hintText: 'Selecciona el modelo',
                        hintStyle: TextStyle(
                          color: widget.error ? Colors.red : Colors.black,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        suffixIcon: _controller.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                color: Colors.grey,
                                onPressed: () {
                                  _controller.clear();
                                  widget.onChanged?.call(null);
                                  setState(() {
                                    _filteredModelos = widget.modelos;
                                  });
                                  _focusNode.requestFocus();
                                },
                              )
                            : null,
                      ),
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                  Opacity(
                    opacity: widget.enabled ? 1.0 : 0.5,
                    child: Icon(
                      _focusNode.hasFocus
                          ? Icons.arrow_drop_down
                          : Icons.arrow_drop_down,
                      color: const Color.fromARGB(255, 86, 86, 86),
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.error && widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 2),
            child: Text(
              widget.errorText!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
      ],
    );
  }
}

class _NavigationButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _NavigationButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

/// Widget para seleccionar un año (modelo)
class _YearPickerField extends StatelessWidget {
  final String? initialYear;
  final void Function(String?) onYearSelected;
  final bool error;
  final String? errorText;

  const _YearPickerField({
    required this.initialYear,
    required this.onYearSelected,
    this.error = false,
    this.errorText,
  });

  List<String> _getYears() {
  // Mostrar únicamente los años solicitados (fijo)
  return ['2025', '2026'];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 240, 240, 240),
            borderRadius: BorderRadius.circular(29),
            border: Border.all(
              color: error ? Colors.red : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: initialYear,
              hint: Text(
                'Selecciona el año del modelo',
                style: TextStyle(
                  color: error ? Colors.red : Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Color(0xFF565656),
                size: 28,
              ),
              dropdownColor: Colors.white,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              menuMaxHeight: 200,
              borderRadius: BorderRadius.circular(16),
              onChanged: onYearSelected,
              items: _getYears()
                  .map(
                    (year) => DropdownMenuItem(value: year, child: Text(year)),
                  )
                  .toList(),
            ),
          ),
        ),
        if (error && errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 2),
            child: Text(
              errorText!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
      ],
    );
  }
}

// Reusable styled input for dialogs
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboard;
  final int? maxLength;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller,
    required this.label,
    this.keyboard,
    this.maxLength,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLength: maxLength,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2)),
        ),
      ),
    );
  }
}