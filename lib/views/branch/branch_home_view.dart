import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';

class BranchHomeView extends StatelessWidget {
  const BranchHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // MOCK: tickets creados por esta sucursal
    final tickets = [
      {
        'id': 'TCK-101',
        'title': 'Sin internet en recepción',
        'status': 'Abierto',
        'priority': 'ROJO',
        'minutes': 25,
      },
      {
        'id': 'TCK-102',
        'title': 'Impresora atascada',
        'status': 'En proceso',
        'priority': 'NARANJA',
        'minutes': 80,
      },
      {
        'id': 'TCK-103',
        'title': 'Cambio de contraseña',
        'status': 'Cerrado',
        'priority': 'VERDE',
        'minutes': 10,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Sucursal',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),

      // menú por rol sucursal
      drawer: const AppDrawer(role: UserRole.sucursal, title: 'Sucursal'),

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
              child: Column(
                children: [
                  // Resumen rápido
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: _MiniPill(
                            label: 'Mis tickets',
                            value: '${tickets.length}',
                            color: const Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniPill(
                            label: 'Abiertos',
                            value:
                                '${tickets.where((t) => t['status'] == 'Abierto').length}',
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                        if (!(!isTablet && !isDesktop)) ...[
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

                  // Lista de mis tickets
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                      itemCount: tickets.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final t = tickets[index];
                        final String id = t['id'] as String;
                        final String title = t['title'] as String;
                        final String status = t['status'] as String;
                        final String priority = t['priority'] as String;
                        final int minutes = t['minutes'] as int;

                        final Color pColor = _priorityColor(priority);

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
                                'branch':
                                    'Sucursal (usuario)', // se coloca el nombre de la sucursal
                                'category': 'Soporte técnico',
                                'priority': priority,
                                'status': status,
                                'createdAt': '2026-01-14 09:20',
                                'isTechnician':
                                    false, // sucursal solo lectura
                                'evidences': [], // luego le pasas las reales
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
                                // indicador color prioridad
                                Container(
                                  width: 10,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: pColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                const SizedBox(width: 12),

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

      // Botón para crear ticket
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.pushNamed(context, '/create-ticket');
        },
        icon: const Icon(Icons.add),
        label: const Text('Crear ticket'),
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
}

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
