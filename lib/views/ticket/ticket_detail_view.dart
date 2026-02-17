import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

enum TicketUserRole { admin, tecnico, sucursal }

class TicketDetailView extends StatefulWidget {
  const TicketDetailView({super.key});

  @override
  State<TicketDetailView> createState() => _TicketDetailViewState();
}

class _TicketDetailViewState extends State<TicketDetailView> {
  final _commentController = TextEditingController();

  bool _initialized = false;

  late Map<String, dynamic> _ticket;
  late TicketUserRole _role;

  late String _status;

  bool get _isAdmin => _role == TicketUserRole.admin;
  bool get _isTechnician => _role == TicketUserRole.tecnico;
  bool get _isBranch => _role == TicketUserRole.sucursal;

  final List<String> _technicians = ['Juan', 'Pedro', 'Luis'];

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

    _ticket = (args is Map<String, dynamic>)
        ? Map<String, dynamic>.from(args)
        : <String, dynamic>{
            'id': 'TCK-101',
            'title': 'Sin internet en recepción',
            'description':
                'No hay conexión en el área de recepción. Se reinició el módem pero sigue sin internet.',
            'branch': 'Sucursal Centro',
            'category': 'Internet / Red',
            'priority': 'ROJO',
            'status': 'Abierto',
            'createdAt': '2026-01-14 09:20',
            'role': 'sucursal',
            'assignedTo': null,
            'evidences': <Map<String, dynamic>>[
              {
                'type': 'image',
                'name': 'foto_1.jpg',
                'path': null,
                'bytes': null,
              },
              {
                'type': 'video',
                'name': 'video_1.mp4',
                'path': null,
                'bytes': null,
              },
            ],
            'comments': <Map<String, String>>[
              {'by': 'Sucursal', 'text': 'Se reinició el módem y sigue igual.'},
              {'by': 'Técnico', 'text': 'Se revisará el cableado y el router.'},
            ],
          };

    final roleString = (_ticket['role'] ?? 'sucursal').toString();

    switch (roleString) {
      case 'admin':
        _role = TicketUserRole.admin;
        break;
      case 'tecnico':
        _role = TicketUserRole.tecnico;
        break;
      default:
        _role = TicketUserRole.sucursal;
    }

    _status = (_ticket['status'] ?? 'Abierto').toString();

    _initialized = true;
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

  Future<void> _addComment({required String by, required String text}) async {
    final List<Map<String, String>> comments = List<Map<String, String>>.from(
      (_ticket['comments'] ?? []).map<Map<String, String>>(
        (e) => {
          'by': (e['by'] ?? '').toString(),
          'text': (e['text'] ?? '').toString(),
        },
      ),
    );

    comments.add({'by': by, 'text': text});

    setState(() {
      _ticket['comments'] = comments;
    });
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
        _status = 'Cerrado';
        _ticket['status'] = 'Cerrado';
        _ticket['closedSolution'] = solution;
      });

      await _addComment(
        by: 'Técnico',
        text: 'Ticket cerrado. Solución: $solution',
      );

      return;
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

      await _addComment(
        by: 'Técnico',
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

      await _addComment(
        by: _isAdmin ? 'Administrador' : 'Técnico',
        text: 'Estado actualizado a "$newStatus".',
      );

      return;
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

  void _downloadTechnicalReport() {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Descargando memoria técnica...'),
    ),
  );

  // Aquí después conectaremos backend
  // Por ahora es solo simulación
  //launchUrl(Uri.parse('$baseUrl/tickets/$id/pdf'));
}


  @override
  Widget build(BuildContext context) {
    final String id = (_ticket['id'] ?? '').toString();
    final String title = (_ticket['title'] ?? '').toString();
    final String description = (_ticket['description'] ?? '').toString();
    final String branch = (_ticket['branch'] ?? '').toString();
    final String category = (_ticket['category'] ?? '').toString();
    final String priority = (_ticket['priority'] ?? 'VERDE').toString();
    final String createdAt = (_ticket['createdAt'] ?? '').toString();

    final evidences = List<Map<String, dynamic>>.from(
      (_ticket['evidences'] ?? []).map<Map<String, dynamic>>(
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

    return Scaffold(
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
      ),
      body: LayoutBuilder(
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
                                  final type = (e['type'] ?? '').toString();
                                  final name = (e['name'] ?? '').toString();
                                  final path = e['path'];
                                  final bytes = e['bytes'];

                                  final bool isImage = type == 'image';
                                  final bool isVideo = type == 'video';

                                  return Container(
                                    margin: const EdgeInsets.only(top: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9FAFB),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        if (isImage)
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: kIsWeb
                                                ? (bytes is Uint8List
                                                      ? Image.memory(
                                                          bytes,
                                                          width: 44,
                                                          height: 44,
                                                          fit: BoxFit.cover,
                                                        )
                                                      : _emptyPreview())
                                                : (path != null
                                                      ? Image.file(
                                                          File(path),
                                                          width: 44,
                                                          height: 44,
                                                          fit: BoxFit.cover,
                                                        )
                                                      : _emptyPreview()),
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
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              isVideo
                                                  ? Icons.videocam
                                                  : Icons.insert_drive_file,
                                              color: isVideo
                                                  ? const Color(0xFFF59E0B)
                                                  : const Color(0xFF4CAF50),
                                            ),
                                          ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF111827),
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {},
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

                    /// ================= HISTORIAL =================
                    _Card(
                      title: 'Historial',
                      trailing: Text(
                        '${comments.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                        ),
                      ),
                      child: comments.isEmpty
                          ? const Text(
                              'Sin comentarios.',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : Column(
                              children: [
                                ...comments.map((c) {
                                  final by = (c['by'] ?? '').toString();
                                  final text = (c['text'] ?? '').toString();
                                  return Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(top: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          by,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          text,
                                          style: const TextStyle(
                                            color: Color(0xFF374151),
                                            fontWeight: FontWeight.w600,
                                          ),
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
                    if (_status == 'Cerrado' && (_isAdmin || _isTechnician))
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
                              style: TextStyle(fontWeight: FontWeight.w800),
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
                            DropdownButtonFormField<String>(
                              value: assignedValue,
                              items: _technicians
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _ticket['assignedTo'] = value;
                                });
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
                            TextField(
                              controller: _commentController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Agregar comentario',
                                prefixIcon: const Icon(Icons.comment),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CAF50),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () async {
                                  final text = _commentController.text.trim();
                                  if (text.isEmpty) return;

                                  await _addComment(by: 'Técnico', text: text);
                                  _commentController.clear();
                                },
                                icon: const Icon(Icons.send),
                                label: const Text(
                                  'Enviar comentario',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    /// ================= ACCIONES SUCURSAL =================
                    if (_isBranch)
                      _Card(
                        title: 'Acciones de sucursal',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (canWriteComment) ...[
                              TextField(
                                controller: _commentController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelText: 'Agregar comentario',
                                  prefixIcon: const Icon(Icons.comment),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: () async {
                                    final text = _commentController.text.trim();
                                    if (text.isEmpty) return;

                                    await _addComment(
                                      by: 'Sucursal',
                                      text: text,
                                    );
                                    _commentController.clear();
                                  },
                                  icon: const Icon(Icons.send),
                                  label: const Text(
                                    'Enviar comentario',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                              const Text(
                                'Este ticket está cerrado.\nSi el problema continúa, puedes solicitar reapertura.',
                                style: TextStyle(
                                  color: Color(0xFF374151),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
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
