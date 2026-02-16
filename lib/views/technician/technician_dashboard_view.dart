import 'package:flutter/material.dart';
import 'package:mesa_sana/widgets/app_drawer.dart';

class TechnicianDashboardView extends StatelessWidget {
  const TechnicianDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    // Tickets MOCK (solo UI)-> se debe cambiar para que se conecte al backend
    final tickets = [
      {
        'id': 'TCK-001',
        'title': 'Sin internet en caja',
        'branch': 'Sucursal Centro',
        'priority': 'ROJO',
        'status': 'Abierto',
        'minutes': 35,
      },
      {
        'id': 'TCK-002',
        'title': 'Impresora no imprime',
        'branch': 'Sucursal Norte',
        'priority': 'NARANJA',
        'status': 'En proceso',
        'minutes': 140,
      },
      {
        'id': 'TCK-003',
        'title': 'Cambio de contraseña',
        'branch': 'Sucursal Sur',
        'priority': 'VERDE',
        'status': 'Abierto',
        'minutes': 15,
      },
      {
        'id': 'TCK-004',
        'title': 'No abre sistema POS',
        'branch': 'Sucursal Centro',
        'priority': 'ROJO',
        'status': 'En proceso',
        'minutes': 210,
      },
    ];

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
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
        actions: [
          IconButton(
            tooltip: 'Buscar',
            onPressed: () {},
            icon: const Icon(Icons.search, color: Color(0xFF1F2937)),
          ),
          IconButton(
            tooltip: 'Filtrar',
            onPressed: () {},
            icon: const Icon(Icons.filter_list, color: Color(0xFF1F2937)),
          ),
        ],
      ),

      // ESTE ES EL MENUUUUU
      drawer: const AppDrawer(role: UserRole.tecnico, title: 'technician'),

      // Responsive: limita ancho en escritorio y centra
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
                  // Barra superior tipo WhatsApp (resumen rápido)
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
                                '${tickets.where((t) => t['priority'] == 'ROJO').length}',
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                        if (!isMobile) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MiniPill(
                              label: 'En proceso',
                              value:
                                  '${tickets.where((t) => t['status'] == 'En proceso').length}',
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Lista de tickets estilo WhatsApp
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                      itemCount: tickets.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final t = tickets[index];
                        final String id = t['id'] as String;
                        final String title = t['title'] as String;
                        final String branch = t['branch'] as String;
                        final String priority = t['priority'] as String;
                        final String status = t['status'] as String;
                        final int minutes = t['minutes'] as int;

                        final Color pColor = _priorityColor(priority);
                        final IconData pIcon = _priorityIcon(priority);

                        return InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/ticket-detail',
                              arguments: {
                                'id': id,
                                'title': title,
                                'description':
                                    'Descripción del problema reportado por la sucursal.',
                                'branch': branch,
                                'category': 'Soporte técnico',
                                'priority': priority,
                                'status': status,
                                'createdAt': '2026-01-14 09:20',
                                'role': 'tecnico', //  IMPORTANTE
                                'evidences': [], // luego serán reales
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
                              children: [
                                // Avatar con prioridad
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

                                // Texto principal
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF111827),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          _StatusChip(status: status),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Text(
                                            id,
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              branch,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          _PriorityPill(
                                            text: priority,
                                            color: pColor,
                                          ),
                                          const SizedBox(width: 10),
                                          Icon(
                                            Icons.schedule,
                                            size: 16,
                                            color: Colors.black.withOpacity(
                                              0.55,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$minutes min',
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF374151),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 10),

                                // Flechita
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.black.withOpacity(0.35),
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

      // Botón flotante tipo WhatsApp (para crear ticket o refrescar, tú decides)
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4CAF50),
        onPressed: () {
          // TODO: acción (crear ticket / refrescar)
        },
        child: const Icon(Icons.add, color: Colors.white),
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
