import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../services/session.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:http_parser/http_parser.dart';
import '../../config/api_config.dart';

MediaType? getMediaType(String name) {
  final ext = name.split('.').last.toLowerCase();

  if (['jpg', 'jpeg', 'png'].contains(ext)) {
    return MediaType('image', ext == 'jpg' ? 'jpeg' : ext);
  }

  if (['mp4', 'mov'].contains(ext)) {
    return MediaType('video', ext);
  }

  return null;
}

class TicketDetailView extends StatefulWidget {
  const TicketDetailView({super.key});

  @override
  State<TicketDetailView> createState() => _TicketDetailViewState();
}

class _TicketDetailViewState extends State<TicketDetailView> {
  final _commentController = TextEditingController();

  List<dynamic> _mensajes = [];

  bool _initialized = false;

  Map<String, dynamic> _ticket = {};
  int? _idRol;
  String? _ticketId;
  String _status = '';

  bool get _isAdmin => _idRol == 1;
  bool get _isTechnician => _idRol == 2;
  bool get _isBranch => _idRol == 3;

  List<dynamic> _technicians = [];
  int? _selectedTecnicoId;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is String) {
      _ticketId = args;
      _loadTicket();
    }

    _initialized = true;
  }

  ///aqui
  /// backend
  ///
  Future<void> _assignTecnico(int idTecnico) async {
    if (_ticketId == null) return;

    final response = await http.post(
      Uri.parse('${ApiConfig.tickets}/$_ticketId/asignar'),

      body: jsonEncode({'id_tecnico': idTecnico}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Técnico asignado')));
    }
  }

  Future<void> _loadTicket() async {
    if (_ticketId == null) return;

    final response = await http.get(
      Uri.parse('${ApiConfig.tickets}/$_ticketId'),
      headers: {
        'Authorization': 'Bearer ${Session.token}',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        _ticket = data;
        _status = data['estado'] ?? '';
        _idRol = Session.idRol;
      });

      if (!mounted) return;
      await _loadMensajes();

      if (!mounted) return;
      await _loadTechnicians();
    }
  }

  Future<void> _loadMensajes() async {
    if (_ticketId == null) return;

    final response = await http.get(
      Uri.parse(ApiConfig.ticketMensajes(int.parse(_ticketId!))),
      headers: {
        'Authorization': 'Bearer ${Session.token}',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _mensajes = jsonDecode(response.body);
      });
    }
  }

  Future<void> _sendFile(PlatformFile file) async {
    if (_ticketId == null) return;

    final uri = Uri.parse(ApiConfig.ticketMensajes(int.parse(_ticketId!)));
    var request = http.MultipartRequest('POST', uri);

    // Solo estos headers son necesarios
    request.headers.addAll({
      'Authorization': 'Bearer ${Session.token}',
      'Accept': 'application/json',
    });

    if (kIsWeb) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'archivo',
          file.bytes!,
          filename: file.name,
          contentType: getMediaType(file.name),
        ),
      );
    } else {
      // Aseguramos el MediaType también en móvil por si acaso
      request.files.add(
        await http.MultipartFile.fromPath(
          'archivo',
          file.path!,
          filename: file.name,
          contentType: getMediaType(file.name),
        ),
      );
    }

    // Laravel a veces ignora el archivo si no hay otros campos presentes
    request.fields['mensaje'] = '';

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("✅ Subida exitosa");
      await _loadTicket(); // 🔥 Recarga TODO el ticket (evidencias actualizadas)
      await _loadMensajes(); // Opcional, para mantener el chat actualizado
    } else {
      print(
        "❌ Error: ${response.body}",
      ); // Revisa qué error devuelve Laravel exactamente
    }
  }

  Future<void> _updateStatusBackend(String newStatus) async {
    if (_ticketId == null) return;

    int estadoId = 1;

    if (newStatus == 'Abierto') estadoId = 1;
    if (newStatus == 'En proceso') estadoId = 2;
    if (newStatus == 'Cerrado') estadoId = 3;

    final response = await http.patch(
      Uri.parse('${ApiConfig.tickets}/$_ticketId/estado'),
      headers: {
        'Authorization': 'Bearer ${Session.token}',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'id_estado': estadoId}),
    );

    if (response.statusCode != 200) {
      print(response.body);
    }
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'ROJO':
        return const Color(0xFFEF4444);
      case 'NARANJA':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF4CAF50);
    }
  }

  Future<void> _addComment({required String text}) async {
    if (_ticketId == null) return;

    final response = await http.post(
      Uri.parse(ApiConfig.ticketMensajes(int.parse(_ticketId!))),
      headers: {
        'Authorization': 'Bearer ${Session.token}',
        'Accept': 'application/json',
        'Content-Type': 'application/json', // 🔥 CLAVE
      },
      body: jsonEncode({
        'mensaje': text, // 🔥 CLAVE
      }),
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      await _loadMensajes();
    } else {
      print("ERROR AL ENVIAR");
    }
  }

  Future<void> _loadTechnicians() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.usuarios}?id_rol=2'),
      headers: {
        'Authorization': 'Bearer ${Session.token}',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _technicians = jsonDecode(response.body);
      });
    }
  }

  Future<String?> _askTextDialog({
    required String title,
    required String label,
    String? hint,
  }) async {
    final ctrl = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: ctrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final v = ctrl.text.trim();
                Navigator.pop(context, v.isEmpty ? null : v);
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );

    return result;
  }

  Future<void> _changeStatus(String newStatus) async {
    final oldStatus = _status;

    // Técnico intenta cerrar
    if (_isTechnician && newStatus == 'Cerrado' && oldStatus != 'Cerrado') {
      final solution = await _askTextDialog(
        title: 'Cerrar ticket',
        label: 'Solución aplicada (obligatorio)',
        hint: 'Ej. Se cambió el cable / se configuró el router / etc.',
      );

      if (solution == null || solution.trim().isEmpty) return;

      setState(() {
        _status = newStatus;
        _ticket['status'] = newStatus;
      });

      if (_isAdmin) {
        await _updateStatusBackend(newStatus);
      } else if (_isTechnician) {
        await _resolverComoTecnico(newStatus);
      } // ESTE ES EL FIX
      await _addComment(text: 'Estado actualizado a "$newStatus".');
    }

    // Técnico reabre
    if (_isTechnician && oldStatus == 'Cerrado' && newStatus != 'Cerrado') {
      final reason = await _askTextDialog(
        title: 'Reabrir ticket',
        label: 'Motivo de reapertura (obligatorio)',
      );

      if (reason == null || reason.trim().isEmpty) return;

      setState(() {
        _status = newStatus;
        _ticket['status'] = newStatus;
        _ticket['reopenReason'] = reason;
      });

      await _updateStatusBackend(newStatus);
      await _addComment(
        text: 'Ticket reabierto a "$newStatus". Motivo: $reason',
      );

      return;
    }

    // Admin o Técnico cambian estado normal
    if (_isTechnician || _isAdmin) {
      setState(() {
        _status = newStatus;
        _ticket['status'] = newStatus;
      });

      await _updateStatusBackend(newStatus); //
      await _addComment(text: 'Estado actualizado a "$newStatus".');

      return;
    }
  }

  Future<void> _resolverComoTecnico(String newStatus) async {
    if (_ticketId == null) return;

    int estadoId = 1;

    if (newStatus == 'Abierto') estadoId = 1;
    if (newStatus == 'En proceso') estadoId = 2;
    if (newStatus == 'Cerrado') estadoId = 3;

    final response = await http.post(
      Uri.parse('${ApiConfig.tickets}/$_ticketId/resolver'),
      headers: {
        'Authorization': 'Bearer ${Session.token}',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'id_estado': estadoId,
        'solucion': 'Solución aplicada',
      }),
    );

    if (response.statusCode != 200) {
      print(response.body);
    }
  }

  /*PDF*/
  Future<void> _downloadTechnicalReport() async {
    if (_ticketId == null) return;

    final response = await http.get(
      Uri.parse('${ApiConfig.tickets}/$_ticketId/memoria'),
      headers: {
        'Authorization': 'Bearer ${Session.token}',
        'Accept': 'application/pdf',
      },
    );

    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;

      if (kIsWeb) {
        // WEB
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", "memoria_ticket_$_ticketId.pdf")
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // MOBILE / DESKTOP
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/memoria_ticket_$_ticketId.pdf');

        await file.writeAsBytes(bytes);

        // ABRIR AUTOMÁTICAMENTE
        await OpenFile.open(file.path);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF guardado en: ${file.path}')),
        );
      }
    } else {
      print(response.body);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error al descargar PDF')));
    }
  }

  Widget _emptyPreview() {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      child: const Icon(Icons.image),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String id = (_ticket['id_ticket'] ?? '—').toString();

    final String title =
        (_ticket['titulo']?.toString().trim().isNotEmpty ?? false)
        ? _ticket['titulo']
        : 'Sin título';

    final String description =
        (_ticket['descripcion']?.toString().trim().isNotEmpty ?? false)
        ? _ticket['descripcion']
        : 'Sin descripción disponible.';

    final String branch =
        (_ticket['sucursal']?.toString().trim().isNotEmpty ?? false)
        ? _ticket['sucursal']
        : 'Sucursal no definida';

    final String category =
        (_ticket['tipo_problema']?.toString().trim().isNotEmpty ?? false)
        ? _ticket['tipo_problema']
        : 'Sin categoría';

    final String priority =
        (_ticket['prioridad']?.toString().trim().isNotEmpty ?? false)
        ? _ticket['prioridad']
        : 'VERDE';

    final String createdAt =
        (_ticket['fecha_creacion']?.toString().trim().isNotEmpty ?? false)
        ? _ticket['fecha_creacion']
        : '';
    //(_ticket['evidencias'] ?? [])
    final evidences = List<Map<String, dynamic>>.from(
      (_ticket['evidencias'] ?? []).map<Map<String, dynamic>>(
        (e) => Map<String, dynamic>.from(e),
      ),
    );

    final comments = List<Map<String, String>>.from(_ticket['comments'] ?? []);

    final pColor = _priorityColor(priority);

    final bool canWriteComment =
        _isAdmin || _isTechnician || (_isBranch && _status != 'Cerrado');

    final assignedValue = _technicians.contains(_ticket['assignedTo'])
        ? _ticket['assignedTo']
        : null;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F3),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            id,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
          bottom: const TabBar(
            labelColor: Color(0xFF111827),
            indicatorColor: Color(0xFF111827),
            tabs: [
              Tab(text: "Detalle"),
              Tab(text: "Chat"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final bool isDesktop = width >= 1024;
                final bool isTablet = width >= 600 && width < 1024;

                final double contentMaxWidth = isDesktop
                    ? 900
                    : (isTablet ? 650 : double.infinity);

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          /// ================= HEADER =================
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: pColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        Icons.confirmation_number,
                                        color: pColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _StatusChip(status: _status),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _Pill(
                                      icon: Icons.store,
                                      text: branch,
                                      color: const Color(0xFF4CAF50),
                                    ),
                                    _Pill(
                                      icon: Icons.category,
                                      text: category,
                                      color: const Color(0xFF2563EB),
                                    ),
                                    _Pill(
                                      icon: Icons.flag,
                                      text: priority,
                                      color: pColor,
                                    ),
                                    if (createdAt.isNotEmpty)
                                      _Pill(
                                        icon: Icons.schedule,
                                        text: createdAt,
                                        color: const Color(0xFF6B7280),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          /// ================= DESCRIPCIÓN =================
                          _Card(
                            title: 'Descripción',
                            child: Text(
                              description,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: Color(0xFF374151),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          /// ================= EVIDENCIAS =================
                          _Card(
                            title: 'Evidencias',
                            trailing: Text(
                              '${evidences.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF111827),
                              ),
                            ),
                            child: evidences.isEmpty
                                ? const Text(
                                    'No hay evidencias adjuntas.',
                                    style: TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : Column(
                                    children: [
                                      ...evidences.map((e) {
                                        final type = (e['type'] ?? '')
                                            .toString();
                                        final name = (e['name'] ?? '')
                                            .toString();
                                        final path = e['path'];
                                        final bytes = e['bytes'];

                                        final bool isImage = type == 'image';
                                        final bool isVideo = type == 'video';

                                        return Container(
                                          margin: const EdgeInsets.only(
                                            top: 10,
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF9FAFB),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFE5E7EB),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              if (isImage)
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  child:
                                                      (path != null &&
                                                          path
                                                              .toString()
                                                              .startsWith(
                                                                'http',
                                                              ))
                                                      ? Image.network(
                                                          path,
                                                          width: 44,
                                                          height: 44,
                                                          fit: BoxFit.cover,
                                                          errorBuilder:
                                                              (
                                                                context,
                                                                error,
                                                                stackTrace,
                                                              ) {
                                                                return _emptyPreview();
                                                              },
                                                        )
                                                      : _emptyPreview(),
                                                )
                                              else
                                                Container(
                                                  width: 44,
                                                  height: 44,
                                                  decoration: BoxDecoration(
                                                    color: isVideo
                                                        ? const Color(
                                                            0xFFF59E0B,
                                                          ).withOpacity(0.15)
                                                        : const Color(
                                                            0xFF4CAF50,
                                                          ).withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    isVideo
                                                        ? Icons.videocam
                                                        : Icons
                                                              .insert_drive_file,
                                                    color: isVideo
                                                        ? const Color(
                                                            0xFFF59E0B,
                                                          )
                                                        : const Color(
                                                            0xFF4CAF50,
                                                          ),
                                                  ),
                                                ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  name,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF111827),
                                                  ),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  if (path != null &&
                                                      path
                                                          .toString()
                                                          .startsWith('http')) {
                                                    launchUrl(Uri.parse(path));
                                                  }
                                                },
                                                child: const Text('Ver'),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                          ),

                          const SizedBox(height: 14),

                          // ================= MEMORIA TÉCNICA PDF =================
                          if (_status == 'Cerrado' &&
                              (_isAdmin || _isTechnician))
                            _Card(
                              title: 'Memoria técnica',
                              child: SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF111827),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: () {
                                    _downloadTechnicalReport();
                                  },
                                  icon: const Icon(Icons.picture_as_pdf),
                                  label: const Text(
                                    'Descargar memoria técnica (PDF)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          /// ================= ACCIONES ADMIN =================
                          if (_isAdmin)
                            _Card(
                              title: 'Acciones del administrador',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DropdownButtonFormField<int>(
                                    value: _selectedTecnicoId,
                                    items: _technicians
                                        .map<DropdownMenuItem<int>>((t) {
                                          return DropdownMenuItem<int>(
                                            value: t['id_usuario'],
                                            child: Text(t['nombre']),
                                          );
                                        })
                                        .toList(),
                                    onChanged: (value) async {
                                      if (value == null) return;

                                      setState(() {
                                        _selectedTecnicoId = value;
                                      });

                                      await _assignTecnico(
                                        value,
                                      ); // 🔥 GUARDA EN BD
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Asignar técnico',
                                      prefixIcon: const Icon(Icons.person),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    value: _status,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'Abierto',
                                        child: Text('Abierto'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'En proceso',
                                        child: Text('En proceso'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Cerrado',
                                        child: Text('Cerrado'),
                                      ),
                                    ],
                                    onChanged: (value) async {
                                      if (value == null) return;
                                      await _changeStatus(value);
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Cambiar estado',
                                      prefixIcon: const Icon(Icons.swap_horiz),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          /// ================= ACCIONES TÉCNICO =================
                          if (_isTechnician)
                            _Card(
                              title: 'Acciones del técnico',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DropdownButtonFormField<String>(
                                    value: _status,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'Abierto',
                                        child: Text('Abierto'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'En proceso',
                                        child: Text('En proceso'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Cerrado',
                                        child: Text('Cerrado'),
                                      ),
                                    ],
                                    onChanged: (value) async {
                                      if (value == null) return;
                                      await _changeStatus(value);
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Cambiar estado',
                                      prefixIcon: const Icon(Icons.swap_horiz),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),

                          /// ================= ACCIONES SUCURSAL =================
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            _buildChatTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth > 900;

        return Center(
          child: Container(
            width: isDesktop ? 800 : double.infinity,
            decoration: const BoxDecoration(color: Color(0xFFF3F4F3)),
            child: Column(
              children: [
                /// ================= MENSAJES =================
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _mensajes.length,
                    itemBuilder: (context, index) {
                      final m = _mensajes[index];
                      final usuario = m['usuario'];
                      final nombre = usuario != null
                          ? usuario['nombre']
                          : 'Usuario';
                      final rol = usuario != null ? usuario['rol'] : '';

                      final bool isMe =
                          (m['id_usuario'] ?? 0) == Session.idUsuario;

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          constraints: const BoxConstraints(maxWidth: 500),
                          decoration: BoxDecoration(
                            color: isMe
                                ? const Color(0xFF2563EB)
                                : const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombre,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isMe ? Colors.white70 : Colors.black54,
                                ),
                              ),

                              if (m['mensaje'] != null &&
                                  m['mensaje'].toString().isNotEmpty)
                                Text(
                                  m['mensaje'],
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                              if (m['archivo'] != null &&
                                  m['archivo'].toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      ApiConfig.archivo(m['archivo']),
                                      width: 200,
                                      height: 200,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            print("ERROR IMG: $error");

                                            return Container(
                                              width: 200,
                                              height: 200,
                                              color: Colors.black12,
                                              child: const Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  size: 40,
                                                ),
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                /// ================= INPUT =================
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                  ),
                  child: Row(
                    children: [
                      /// 📎 BOTÓN SUBIR ARCHIVO
                      IconButton(
                        icon: const Icon(Icons.attach_file),
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            allowMultiple: false,
                            type: FileType.any,
                          );

                          if (result == null) return;

                          final file = result.files.first;

                          await _sendFile(file);
                        },
                      ),

                      /// ✍️ INPUT
                      Expanded(
                        child: TextField(
                          controller: _commentController,

                          textInputAction: TextInputAction
                              .send, // 🔥 cambia el botón del teclado

                          onSubmitted: (value) async {
                            final text = value.trim();
                            if (text.isEmpty) return;

                            print("ENTER FUNCIONA");

                            await _addComment(text: text);
                            _commentController.clear();
                          },

                          decoration: const InputDecoration(
                            hintText: "Escribe un mensaje...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(14),
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      /// 📤 BOTÓN ENVIAR
                      GestureDetector(
                        onTap: () async {
                          final text = _commentController.text.trim();
                          if (text.isEmpty) return;

                          await _addComment(text: text);
                          _commentController.clear();
                        },
                        child: Container(
                          height: 48,
                          width: 48,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.send, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ===================== UI COMPONENTS =====================

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _Card({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;

    switch (status) {
      case 'Abierto':
        bg = const Color(0xFFEEF2FF);
        fg = const Color(0xFF3730A3);
        break;
      case 'En proceso':
        bg = const Color(0xFFFFF7ED);
        fg = const Color(0xFF9A3412);
        break;
      case 'Cerrado':
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF065F46);
        break;
      default:
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF374151);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _Pill({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
