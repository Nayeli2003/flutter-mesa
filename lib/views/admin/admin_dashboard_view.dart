import 'package:flutter/material.dart';
import 'package:mesa_sana/widgets/app_drawer.dart';

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos MOCK (solo para la vista)
    final stats = {
      'Total tickets': 128,
      'Abiertos': 34,
      'En proceso': 61,
      'Cerrados': 33,
    };

    final priority = {
      'Rojo (Urgente)': 12,
      'Naranja (Medio)': 25,
      'Verde (Bajo)': 91,
    };

    final sla = {
      'SLA cumplidos': 110,
      'SLA vencidos': 18,
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Administrador',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),

        // ESTE ES EL MENUUUUU
      drawer: const AppDrawer(
        role: UserRole.admin, 
        title: 'Admin'
        ),
      // Responsive 
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          // Breakpoints
          final bool isMobile = width < 600;
          final bool isTablet = width >= 600 && width < 1024;
          final bool isDesktop = width >= 1024;

          // Ancho máximo del contenido (para que no se estire en escritorio)
          final double contentMaxWidth = isDesktop ? 900 : (isTablet ? 650 : 480);

          // Grid adaptable
          final int gridCols = isDesktop ? 4 : (isTablet ? 3 : 2);

          // Para que las cards no se vean grandes
          final double ratio = isDesktop ? 2.2 : (isTablet ? 2.0 : 1.7);

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 24 : 16,
              vertical: 16,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: Column(
                  children: [
                    // Encabezado
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
                      child: const Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Color(0xFF4CAF50),
                            child: Icon(Icons.admin_panel_settings,
                                color: Colors.white),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Panel de control y métricas',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Cards: estado de tickets
                    const _SectionTitle(title: 'Resumen de tickets'),
                    const SizedBox(height: 10),
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridCols,
                        childAspectRatio: ratio,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      children: [
                        _StatCard(
                          title: 'Total',
                          value: '${stats['Total tickets']}',
                          icon: Icons.confirmation_number,
                          color: const Color(0xFF4CAF50),
                        ),
                        _StatCard(
                          title: 'Abiertos',
                          value: '${stats['Abiertos']}',
                          icon: Icons.mark_email_unread,
                          color: const Color(0xFFEF4444),
                        ),
                        _StatCard(
                          title: 'En proceso',
                          value: '${stats['En proceso']}',
                          icon: Icons.timelapse,
                          color: const Color(0xFFF59E0B),
                        ),
                        _StatCard(
                          title: 'Cerrados',
                          value: '${stats['Cerrados']}',
                          icon: Icons.verified,
                          color: const Color(0xFF10B981),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Prioridades
                    const _SectionTitle(title: 'Tickets por prioridad'),
                    const SizedBox(height: 10),
                    _InfoTile(
                      label: '🟥 Rojo (Urgente)',
                      value: '${priority['Rojo (Urgente)']}',
                    ),
                    const SizedBox(height: 10),
                    _InfoTile(
                      label: '🟧 Naranja (Medio)',
                      value: '${priority['Naranja (Medio)']}',
                    ),
                    const SizedBox(height: 10),
                    _InfoTile(
                      label: '🟩 Verde (Bajo)',
                      value: '${priority['Verde (Bajo)']}',
                    ),

                    const SizedBox(height: 18),

                    // SLA (responsive: en mobile columna, en tablet/desktop fila)
                    const _SectionTitle(title: 'SLA'),
                    const SizedBox(height: 10),

                    if (isMobile)
                      Column(
                        children: [
                          _StatCard(
                            title: 'Cumplidos',
                            value: '${sla['SLA cumplidos']}',
                            icon: Icons.check_circle,
                            color: const Color(0xFF10B981),
                          ),
                          const SizedBox(height: 12),
                          _StatCard(
                            title: 'Vencidos',
                            value: '${sla['SLA vencidos']}',
                            icon: Icons.warning_amber_rounded,
                            color: const Color(0xFFEF4444),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Cumplidos',
                              value: '${sla['SLA cumplidos']}',
                              icon: Icons.check_circle,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'Vencidos',
                              value: '${sla['SLA vencidos']}',
                              icon: Icons.warning_amber_rounded,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 22),

                    // Botones responsivos
                    const _SectionTitle(title: 'Administración'),
                    const SizedBox(height: 10),

                    if (isDesktop)
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pushNamed(context, '/admin-users');
                                },
                                icon: const Icon(Icons.group, color: Colors.white),
                                label: const Text(
                                  'Gestión de usuarios',
                                  style: TextStyle(fontSize: 15, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF4CAF50)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pushNamed(context, '/admin-metrics');
                                },
                                icon: const Icon(Icons.bar_chart, color: Color(0xFF4CAF50)),
                                label: const Text(
                                  'Ver métricas',
                                  style: TextStyle(fontSize: 15, color: Color(0xFF4CAF50)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () {},
                              icon: const Icon(Icons.group, color: Colors.white),
                              label: const Text(
                                'Gestión de usuarios',
                                style: TextStyle(fontSize: 15, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF4CAF50)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () {},
                              icon: const Icon(Icons.bar_chart, color: Color(0xFF4CAF50)),
                              label: const Text(
                                'Ver métricas detalladas',
                                style: TextStyle(fontSize: 15, color: Color(0xFF4CAF50)),
                              ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 20),
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

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}
