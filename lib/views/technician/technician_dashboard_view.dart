import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mesa_sana/widgets/app_drawer.dart';
import '../../services/session.dart';

class TechnicianDashboardView extends StatefulWidget {
  const TechnicianDashboardView({super.key});

  @override
  State<TechnicianDashboardView> createState() =>
      _TechnicianDashboardViewState();
}

const String baseUrl = 'http://localhost:8000';

class _TechnicianDashboardViewState extends State<TechnicianDashboardView> {
  List<dynamic> tickets = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/mis-tickets'),
      headers: {
        'Authorization': 'Bearer ${Session.token}',
        'Accept': 'application/json',
      },
    );

    if (res.statusCode == 200) {
      setState(() {
        tickets = jsonDecode(res.body);
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Técnico',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      drawer: const AppDrawer(role: UserRole.tecnico, title: 'technician'),

      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final bool isMobile = width < 600;
          final bool isTablet = width >= 600 && width < 1024;
          final bool isDesktop = width >= 1024;

          final double contentMaxWidth = isDesktop
              ? 900
              : (isTablet ? 650 : double.infinity);

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: _MiniPill(
                            label: 'Asignados',
                            value: '${tickets.length}',
                            color: const Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniPill(
                            label: 'Urgentes',
                            value:
                                '${tickets.where((t) => t['prioridad'] == 'Alta').length}',
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                      itemCount: tickets.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final t = tickets[index];

                        final id = t['id_ticket'].toString();
                        final title = t['titulo'].toString();
                        final branch = t['sucursal'].toString();
                        final priority = t['prioridad'].toString();
                        final status = t['estado'].toString();

                        final Color pColor = _priorityColor(priority);
                        final IconData pIcon = _priorityIcon(priority);

                        return InkWell(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/ticket-detail',
                              arguments: {
                                'id': id,
                                'title': title,
                                'description': t['descripcion'] ?? '',
                                'branch': branch,
                                'category': t['tipo_problema'] ?? '',
                                'priority': priority,
                                'status': status,
                                'createdAt': t['fecha_creacion'] ?? '',
                                'role': 'tecnico',
                                'evidences': [],
                                'comments': [],
                              },
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
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
                            child: Row(
                              // ESTE ES EL FIX
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: pColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(pIcon, color: pColor),
                                ),
                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(branch),
                                      Text(status),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
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

  IconData _priorityIcon(String p) {
    switch (p) {
      case 'ROJO':
        return Icons.priority_high;
      case 'NARANJA':
        return Icons.warning_amber_rounded;
      default:
        return Icons.low_priority;
    }
  }
}
// ---------- Widgets pequeños (UI) ----------

class _MiniPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
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

class _PriorityPill extends StatelessWidget {
  final String text;
  final Color color;
  const _PriorityPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}
