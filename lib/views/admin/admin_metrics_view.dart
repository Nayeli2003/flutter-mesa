import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';

class AdminMetricsView extends StatefulWidget {
  const AdminMetricsView({super.key});

  @override
  State<AdminMetricsView> createState() => _AdminMetricsViewState();
}

class _AdminMetricsViewState extends State<AdminMetricsView> {
  DateTime? _from;
  DateTime? _to;

  // ===== MOCK DATA =====
  // Para backend: aquí vendría de tu API según el rango de fechas.
  final Map<String, int> _ticketsByStatus = {
    'Abiertos': 34,
    'En proceso': 61,
    'Cerrados': 33,
  };

  final Map<String, int> _ticketsByPriority = {
    'ROJO': 12,
    'NARANJA': 25,
    'VERDE': 91,
  };

  final Map<String, int> _sla = {
    'Cumplidos': 110,
    'Vencidos': 18,
  };

  // Tickets resueltos por técnico (CERRADOS)
  final List<Map<String, dynamic>> _resolvedByTech = [
    {'techId': 'TEC-001', 'techName': 'Juan Pérez', 'resolved': 14},
    {'techId': 'TEC-002', 'techName': 'Ana López', 'resolved': 9},
    {'techId': 'TEC-003', 'techName': 'Luis Hernández', 'resolved': 6},
    {'techId': 'TEC-004', 'techName': 'María Gómez', 'resolved': 4},
  ];

  Future<void> _pickFrom() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _from ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _from = picked);
  }

  Future<void> _pickTo() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _to ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _to = picked);
  }

  void _clearFilters() {
    setState(() {
      _from = null;
      _to = null;
    });
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'ROJO':
        return const Color(0xFFEF4444);
      case 'NARANJA':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF10B981);
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Abiertos':
        return const Color(0xFFEF4444);
      case 'En proceso':
        return const Color(0xFFF59E0B);
      case 'Cerrados':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalTickets = _ticketsByStatus.values.fold(0, (a, b) => a + b);

    // Ordenar técnicos por resueltos desc
    final techSorted = [..._resolvedByTech]
      ..sort((a, b) => (b['resolved'] as int).compareTo(a['resolved'] as int));

    final int maxResolved = techSorted.isEmpty
        ? 0
        : (techSorted.first['resolved'] as int);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Métricas / SLA',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),
      drawer: const AppDrawer(
        role: UserRole.admin,
        title: 'Admin',
        subtitle: 'Mesa de ayuda',
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          final bool isMobile = width < 600;
          final bool isTablet = width >= 600 && width < 1024;
          final bool isDesktop = width >= 1024;

          final double contentMaxWidth =
              isDesktop ? 980 : (isTablet ? 760 : double.infinity);

          final int gridCols = isDesktop ? 4 : (isTablet ? 3 : 2);

          final double ratio = isDesktop ? 2.2 : (isTablet ? 2.1 : 1.8);

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 24 : 16,
              vertical: 16,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== Filtros por fecha =====
                    _Card(
                      title: 'Filtros',
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: isDesktop ? 260 : double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _pickFrom,
                              icon: const Icon(Icons.date_range),
                              label: Text('Desde: ${_fmtDate(_from)}'),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: isDesktop ? 260 : double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _pickTo,
                              icon: const Icon(Icons.event),
                              label: Text('Hasta: ${_fmtDate(_to)}'),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: isDesktop ? 180 : double.infinity,
                            child: TextButton.icon(
                              onPressed: _clearFilters,
                              icon: const Icon(Icons.clear),
                              label: const Text('Limpiar'),
                            ),
                          ),
                          SizedBox(
                            width: isDesktop ? 240 : double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // TODO: aquí llamarías API con (_from, _to)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Filtro aplicado (UI mock)'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.search),
                              label: const Text('Aplicar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ===== Resumen general =====
                    const _SectionTitle(title: 'Resumen general'),
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
                          value: '$totalTickets',
                          icon: Icons.confirmation_number,
                          color: const Color(0xFF4CAF50),
                        ),
                        _StatCard(
                          title: 'SLA cumplidos',
                          value: '${_sla['Cumplidos'] ?? 0}',
                          icon: Icons.check_circle,
                          color: const Color(0xFF10B981),
                        ),
                        _StatCard(
                          title: 'SLA vencidos',
                          value: '${_sla['Vencidos'] ?? 0}',
                          icon: Icons.warning_amber_rounded,
                          color: const Color(0xFFEF4444),
                        ),
                        _StatCard(
                          title: 'Cerrados',
                          value: '${_ticketsByStatus['Cerrados'] ?? 0}',
                          icon: Icons.verified,
                          color: const Color(0xFF065F46),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ===== Tickets por estado =====
                    const _SectionTitle(title: 'Tickets por estado'),
                    const SizedBox(height: 10),
                    _Card(
                      title: 'Estados',
                      child: Column(
                        children: _ticketsByStatus.entries.map((e) {
                          final c = _statusColor(e.key);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _MetricRow(
                              label: e.key,
                              value: e.value,
                              color: c,
                              maxValue: totalTickets == 0 ? 1 : totalTickets,
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ===== Tickets por prioridad =====
                    const _SectionTitle(title: 'Tickets por prioridad'),
                    const SizedBox(height: 10),
                    _Card(
                      title: 'Prioridades',
                      child: Column(
                        children: _ticketsByPriority.entries.map((e) {
                          final c = _priorityColor(e.key);
                          final max = _ticketsByPriority.values.isEmpty
                              ? 1
                              : _ticketsByPriority.values
                                  .reduce((a, b) => a > b ? a : b);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _MetricRow(
                              label: e.key,
                              value: e.value,
                              color: c,
                              maxValue: max == 0 ? 1 : max,
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ===== Tickets resueltos por técnico =====
                    const _SectionTitle(
                        title: 'Tickets resueltos por técnico'),
                    const SizedBox(height: 10),

                    if (isMobile)
                      _Card(
                        title: 'Ranking',
                        child: Column(
                          children: techSorted.map((t) {
                            final String name = t['techName']?.toString() ?? '';
                            final String id = t['techId']?.toString() ?? '';
                            final int resolved = t['resolved'] as int;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: const Color(0xFFE5E7EB)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$name • $id',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _MetricRow(
                                    label: 'Resueltos',
                                    value: resolved,
                                    color: const Color(0xFF2563EB),
                                    maxValue: maxResolved == 0 ? 1 : maxResolved,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      )
                    else
                      _ResolvedByTechTable(
                        data: techSorted,
                        maxValue: maxResolved == 0 ? 1 : maxResolved,
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

/* ===================== COMPONENTES UI ===================== */

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: Color(0xFF1F2937),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;

  const _Card({required this.title, required this.child});

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
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
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
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
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
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
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
          )
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final int maxValue;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.color,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final double pct = (value / (maxValue == 0 ? 1 : maxValue)).clamp(0, 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            Text(
              '$value',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 10,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

/* ===================== TABLE RESUELTOS POR TECNICO ===================== */

class _ResolvedByTechTable extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final int maxValue;

  const _ResolvedByTechTable({required this.data, required this.maxValue});

  @override
  State<_ResolvedByTechTable> createState() => _ResolvedByTechTableState();
}

class _ResolvedByTechTableState extends State<_ResolvedByTechTable> {
  final ScrollController _h = ScrollController();
  final ScrollController _v = ScrollController();

  @override
  void dispose() {
    _h.dispose();
    _v.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const _EmptyBox(text: 'No hay técnicos para mostrar.');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ScrollConfiguration(
          behavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {
              PointerDeviceKind.mouse,
              PointerDeviceKind.touch,
              PointerDeviceKind.trackpad,
            },
          ),
          child: Scrollbar(
            controller: _h,
            thumbVisibility: true,
            trackVisibility: true,
            notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
            child: SingleChildScrollView(
              controller: _h,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 900),
                child: Scrollbar(
                  controller: _v,
                  thumbVisibility: true,
                  trackVisibility: true,
                  notificationPredicate: (n) => n.metrics.axis == Axis.vertical,
                  child: SingleChildScrollView(
                    controller: _v,
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('ID Técnico')),
                        DataColumn(label: Text('Nombre')),
                        DataColumn(label: Text('Resueltos')),
                        DataColumn(label: Text('Progreso')),
                      ],
                      rows: widget.data.map((t) {
                        final String id = t['techId']?.toString() ?? '';
                        final String name = t['techName']?.toString() ?? '';
                        final int resolved = t['resolved'] as int;

                        final pct = (resolved / widget.maxValue)
                            .clamp(0.0, 1.0)
                            .toDouble();

                        return DataRow(
                          cells: [
                            DataCell(Text(id)),
                            DataCell(Text(name)),
                            DataCell(Text('$resolved')),
                            DataCell(
                              SizedBox(
                                width: 260,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    minHeight: 10,
                                    backgroundColor:
                                        const Color(0xFFE5E7EB),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            Color(0xFF2563EB)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String text;
  const _EmptyBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
