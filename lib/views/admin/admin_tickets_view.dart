import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';
import 'dart:ui' show PointerDeviceKind;

enum AdminTicketStatus { abierto, enProceso, cerrado }

enum AdminTicketPriority { verde, naranja, rojo }

class AdminTicketModel {
  final String folio;
  final String titulo;
  final String branchId;
  final String sucursal;
  final String tecnico;
  final DateTime fecha;
  final AdminTicketStatus status;
  final AdminTicketPriority priority;
  final bool slaCumple;

  const AdminTicketModel({
    required this.folio,
    required this.titulo,
    required this.branchId,
    required this.sucursal,
    required this.tecnico,
    required this.fecha,
    required this.status,
    required this.priority,
    required this.slaCumple,
  });
}

class AdminTicketsView extends StatefulWidget {
  const AdminTicketsView({super.key});

  @override
  State<AdminTicketsView> createState() => _AdminTicketsViewState();
}

class _AdminTicketsViewState extends State<AdminTicketsView> {
  final TextEditingController _searchCtrl = TextEditingController();

  AdminTicketStatus? _status;
  AdminTicketPriority? _priority;

  String? _branch;
  String? _tech;

  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Datos dummy
  List<AdminTicketModel> _ticketsFake() => [
    AdminTicketModel(
      folio: 'TK-001',
      titulo: 'Sin internet en recepción',
      branchId: 'SUC-001',
      sucursal: 'Sucursal Centro',
      tecnico: 'Juan Pérez',
      fecha: DateTime(2026, 1, 14, 9, 20),
      status: AdminTicketStatus.abierto,
      priority: AdminTicketPriority.rojo,
      slaCumple: false,
    ),
    AdminTicketModel(
      folio: 'TK-002',
      titulo: 'Impresora no imprime',
      branchId: 'SUC-002',
      sucursal: 'Sucursal Norte',
      tecnico: 'Ana López',
      fecha: DateTime(2026, 1, 14, 13, 10),
      status: AdminTicketStatus.enProceso,
      priority: AdminTicketPriority.naranja,
      slaCumple: true,
    ),
    AdminTicketModel(
      folio: 'TK-003',
      titulo: 'Actualización aplicada',
      branchId: 'SUC-003',
      sucursal: 'Sucursal Sur',
      tecnico: 'Juan Pérez',
      fecha: DateTime(2026, 1, 13, 9, 5),
      status: AdminTicketStatus.cerrado,
      priority: AdminTicketPriority.verde,
      slaCumple: true,
    ),
  ];

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _fromDate = picked);
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _toDate = picked);
  }

  void _clearFilters() {
    setState(() {
      _searchCtrl.clear();
      _status = null;
      _priority = null;
      _branch = null;
      _tech = null;
      _fromDate = null;
      _toDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final all = _ticketsFake();

    // filtros
    List<AdminTicketModel> filtered = all;

    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      filtered = filtered.where((t) {
        return t.folio.toLowerCase().contains(q) ||
            t.titulo.toLowerCase().contains(q) ||
            t.branchId.toLowerCase().contains(q) ||
            t.sucursal.toLowerCase().contains(q) ||
            t.tecnico.toLowerCase().contains(q);
      }).toList();
    }

    if (_status != null) {
      filtered = filtered.where((t) => t.status == _status).toList();
    }

    if (_priority != null) {
      filtered = filtered.where((t) => t.priority == _priority).toList();
    }

    if (_branch != null && _branch!.trim().isNotEmpty) {
      final b = _branch!.trim().toLowerCase();
      filtered = filtered
          .where(
            (t) =>
                t.branchId.toLowerCase().contains(b) ||
                t.sucursal.toLowerCase().contains(b),
          )
          .toList();
    }

    if (_tech != null && _tech!.trim().isNotEmpty) {
      final te = _tech!.trim().toLowerCase();
      filtered = filtered
          .where((t) => t.tecnico.toLowerCase().contains(te))
          .toList();
    }

    if (_fromDate != null || _toDate != null) {
      filtered = filtered.where((t) {
        final d = DateTime(t.fecha.year, t.fecha.month, t.fecha.day);
        final from = _fromDate == null
            ? null
            : DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
        final to = _toDate == null
            ? null
            : DateTime(_toDate!.year, _toDate!.month, _toDate!.day);

        final okFrom = from == null || !d.isBefore(from);
        final okTo = to == null || !d.isAfter(to);
        return okFrom && okTo;
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Todos los tickets')),
      drawer: const AppDrawer(
        role: UserRole.admin,
        title: 'Admin',
        subtitle: 'Mesa de ayuda',
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWide ? 1200 : double.infinity,
              ),
              child: Padding(
                padding: EdgeInsets.all(isWide ? 16 : 12),
                child: Column(
                  children: [
                    _AdminFiltersBar(
                      searchCtrl: _searchCtrl,
                      status: _status,
                      priority: _priority,
                      branch: _branch,
                      tech: _tech,
                      fromDate: _fromDate,
                      toDate: _toDate,
                      onStatusChanged: (v) => setState(() => _status = v),
                      onPriorityChanged: (v) => setState(() => _priority = v),
                      onBranchChanged: (v) => setState(() => _branch = v),
                      onTechChanged: (v) => setState(() => _tech = v),
                      onPickFrom: _pickFromDate,
                      onPickTo: _pickToDate,
                      onClear: _clearFilters,
                      onChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: isWide
                          ? _AdminTicketsTable(tickets: filtered)
                          : _AdminTicketsCards(tickets: filtered),
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

/* ===================== FILTER BAR (RESPONSIVE) ===================== */

class _AdminFiltersBar extends StatelessWidget {
  final TextEditingController searchCtrl;

  final AdminTicketStatus? status;
  final AdminTicketPriority? priority;

  final String? branch;
  final String? tech;

  final DateTime? fromDate;
  final DateTime? toDate;

  final ValueChanged<AdminTicketStatus?> onStatusChanged;
  final ValueChanged<AdminTicketPriority?> onPriorityChanged;
  final ValueChanged<String?> onBranchChanged;
  final ValueChanged<String?> onTechChanged;

  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;

  final VoidCallback onClear;
  final VoidCallback onChanged;

  const _AdminFiltersBar({
    required this.searchCtrl,
    required this.status,
    required this.priority,
    required this.branch,
    required this.tech,
    required this.fromDate,
    required this.toDate,
    required this.onStatusChanged,
    required this.onPriorityChanged,
    required this.onBranchChanged,
    required this.onTechChanged,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onClear,
    required this.onChanged,
  });

  String _fmt(DateTime? d) {
    if (d == null) return '—';
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  void _openMobileFilters(BuildContext context) {
    AdminTicketStatus? s = status;
    AdminTicketPriority? p = priority;
    final branchCtrl = TextEditingController(text: branch ?? '');
    final techCtrl = TextEditingController(text: tech ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Filtros',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setLocal(() {
                              s = null;
                              p = null;
                              branchCtrl.clear();
                              techCtrl.clear();
                            });
                          },
                          icon: const Icon(Icons.clear),
                          label: const Text('Limpiar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<AdminTicketStatus>(
                      value: s,
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Estado: Todos'),
                        ),
                        DropdownMenuItem(
                          value: AdminTicketStatus.abierto,
                          child: Text('Abierto'),
                        ),
                        DropdownMenuItem(
                          value: AdminTicketStatus.enProceso,
                          child: Text('En proceso'),
                        ),
                        DropdownMenuItem(
                          value: AdminTicketStatus.cerrado,
                          child: Text('Cerrado'),
                        ),
                      ],
                      onChanged: (v) => setLocal(() => s = v),
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<AdminTicketPriority>(
                      value: p,
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Prioridad: Todas'),
                        ),
                        DropdownMenuItem(
                          value: AdminTicketPriority.verde,
                          child: Text('Verde'),
                        ),
                        DropdownMenuItem(
                          value: AdminTicketPriority.naranja,
                          child: Text('Naranja'),
                        ),
                        DropdownMenuItem(
                          value: AdminTicketPriority.rojo,
                          child: Text('Rojo'),
                        ),
                      ],
                      onChanged: (v) => setLocal(() => p = v),
                      decoration: const InputDecoration(
                        labelText: 'Prioridad',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: branchCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Sucursal (ID o nombre)',
                        prefixIcon: Icon(Icons.store),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: techCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Técnico',
                        prefixIcon: Icon(Icons.engineering),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onPickFrom,
                            icon: const Icon(Icons.date_range),
                            label: Text('Desde: ${_fmt(fromDate)}'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onPickTo,
                            icon: const Icon(Icons.date_range),
                            label: Text('Hasta: ${_fmt(toDate)}'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          onStatusChanged(s);
                          onPriorityChanged(p);
                          onBranchChanged(
                            branchCtrl.text.trim().isEmpty
                                ? null
                                : branchCtrl.text.trim(),
                          );
                          onTechChanged(
                            techCtrl.text.trim().isEmpty
                                ? null
                                : techCtrl.text.trim(),
                          );
                          onChanged();
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Aplicar'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, c) {
            final isMobile = c.maxWidth < 800;
            final isWide = c.maxWidth >= 1100;

            if (isMobile) {
              // Compacto en celular: solo buscar + botón filtros + limpiar
              return Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchCtrl,
                      onChanged: (_) => onChanged(),
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'Buscar',
                        hintText: 'Folio / título / sucursal / técnico',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    tooltip: 'Filtros',
                    onPressed: () => _openMobileFilters(context),
                    icon: const Icon(Icons.tune),
                  ),
                  IconButton(
                    tooltip: 'Limpiar',
                    onPressed: onClear,
                    icon: const Icon(Icons.clear),
                  ),
                ],
              );
            }

            //  Desktop / Tablet: completo
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: isWide ? 360 : 320,
                  child: TextField(
                    controller: searchCtrl,
                    onChanged: (_) => onChanged(),
                    decoration: InputDecoration(
                      labelText: 'Buscar (folio, título, sucursal, técnico)',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: isWide ? 200 : 190,
                  child: DropdownButtonFormField<AdminTicketStatus>(
                    value: status,
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text('Estado: Todos'),
                      ),
                      DropdownMenuItem(
                        value: AdminTicketStatus.abierto,
                        child: Text('Abierto'),
                      ),
                      DropdownMenuItem(
                        value: AdminTicketStatus.enProceso,
                        child: Text('En proceso'),
                      ),
                      DropdownMenuItem(
                        value: AdminTicketStatus.cerrado,
                        child: Text('Cerrado'),
                      ),
                    ],
                    onChanged: onStatusChanged,
                    decoration: InputDecoration(
                      labelText: 'Estado',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: isWide ? 220 : 200,
                  child: DropdownButtonFormField<AdminTicketPriority>(
                    value: priority,
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text('Prioridad: Todas'),
                      ),
                      DropdownMenuItem(
                        value: AdminTicketPriority.verde,
                        child: Text('Verde'),
                      ),
                      DropdownMenuItem(
                        value: AdminTicketPriority.naranja,
                        child: Text('Naranja'),
                      ),
                      DropdownMenuItem(
                        value: AdminTicketPriority.rojo,
                        child: Text('Rojo'),
                      ),
                    ],
                    onChanged: onPriorityChanged,
                    decoration: InputDecoration(
                      labelText: 'Prioridad',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: isWide ? 220 : 200,
                  child: TextField(
                    onChanged: (v) =>
                        onBranchChanged(v.trim().isEmpty ? null : v),
                    decoration: InputDecoration(
                      labelText: 'Sucursal (ID o nombre)',
                      prefixIcon: const Icon(Icons.store),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: isWide ? 220 : 200,
                  child: TextField(
                    onChanged: (v) =>
                        onTechChanged(v.trim().isEmpty ? null : v),
                    decoration: InputDecoration(
                      labelText: 'Técnico',
                      prefixIcon: const Icon(Icons.engineering),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: OutlinedButton.icon(
                    onPressed: onPickFrom,
                    icon: const Icon(Icons.date_range),
                    label: Text('Desde: ${_fmt(fromDate)}'),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: OutlinedButton.icon(
                    onPressed: onPickTo,
                    icon: const Icon(Icons.date_range),
                    label: Text('Hasta: ${_fmt(toDate)}'),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: TextButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.clear),
                    label: const Text('Limpiar'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/* ===================== MOBILE: CARDS ===================== */

class _AdminTicketsCards extends StatelessWidget {
  final List<AdminTicketModel> tickets;
  const _AdminTicketsCards({required this.tickets});

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) {
      return const Center(child: Text('No hay tickets para mostrar.'));
    }

    return ListView.separated(
      itemCount: tickets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final t = tickets[index];

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _priorityColor(t.priority),
              child: const Icon(Icons.confirmation_number, color: Colors.white),
            ),
            title: Text(
              '${t.folio} • ${t.titulo}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${t.sucursal}\n'
              'Técnico: ${t.tecnico}\n'
              '${_statusText(t.status)} • ${_fmtDate(t.fecha)} • SLA: ${t.slaCumple ? "Cumple" : "No cumple"}',
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/ticket-detail',
                arguments: {
                  'id': t.folio,
                  'title': t.titulo,
                  'branch': t.sucursal,
                  'priority': _priorityText(t.priority).toUpperCase(),
                  'status': _statusText(t.status),
                  'createdAt': _fmtDate(t.fecha),
                  'isTechnician': false,
                  'category': 'Admin',
                  'description': 'Detalle pendiente de backend',
                  'evidences': <Map<String, dynamic>>[],
                  'comments': <Map<String, String>>[],
                },
              );
            },
          ),
        );
      },
    );
  }
}

/* ===================== WEB/DESKTOP: TABLE (SIN HUECOS) ===================== */

class _AdminTicketsTable extends StatefulWidget {
  final List<AdminTicketModel> tickets;
  const _AdminTicketsTable({required this.tickets});

  @override
  State<_AdminTicketsTable> createState() => _AdminTicketsTableState();
}

class _AdminTicketsTableState extends State<_AdminTicketsTable> {
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
    if (widget.tickets.isEmpty) {
      return const Center(child: Text('No hay tickets para mostrar.'));
    }

    // Ajusta estos valores si quieres MÁS compacto todavía
    const double wFolio = 80;
    const double wTitulo = 340;
    const double wTecnico = 170;
    const double wSucursal = 200;
    const double wEstado = 120;
    const double wPrioridad = 120;
    const double wSla = 110;
    const double wAccion = 90;

    const double columnSpacing = 12;
    const double horizontalMargin = 10;

    const int cols = 8;
    const double sumWidths =
        wFolio +
        wTitulo +
        wTecnico +
        wSucursal +
        wEstado +
        wPrioridad +
        wSla +
        wAccion;

    //  minWidth EXACTO = suma + espacios + márgenes (esto quita el “hueco” raro)
    final double minWidth =
        sumWidths + (columnSpacing * (cols - 1)) + (horizontalMargin * 2);

    return Card(
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
              constraints: BoxConstraints(minWidth: minWidth),
              child: Scrollbar(
                controller: _v,
                thumbVisibility: true,
                trackVisibility: true,
                notificationPredicate: (n) => n.metrics.axis == Axis.vertical,
                child: SingleChildScrollView(
                  controller: _v,
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    columnSpacing: 8, // ↓ más pegadito
                    horizontalMargin: 10,
                    dataRowMinHeight: 44,
                    dataRowMaxHeight: 56,
                    headingRowHeight: 48,
                    columns: const [
                      DataColumn(label: Text('Folio')),
                      DataColumn(label: Text('Título')),
                      DataColumn(label: Text('Técnico')),
                      DataColumn(label: Text('Sucursal')),
                      DataColumn(label: Text('Estado')),
                      DataColumn(label: Text('Prioridad')),
                      DataColumn(label: Text('SLA')),
                      DataColumn(label: Text('Acción')),
                    ],
                    rows: widget.tickets.map((t) {
                      return DataRow(
                        cells: [
                          DataCell(Text(t.folio)),

                          // TÍTULO SIN WIDTH FIJO (esto quita el hueco)
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 260,
                              ), // ajusta 240-300
                              child: Text(
                                t.titulo,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),

                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 160),
                              child: Text(
                                t.tecnico,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 200),
                              child: Text(
                                t.sucursal,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(Text(_statusText(t.status))),
                          DataCell(_PriorityChip(priority: t.priority)),
                          DataCell(_SlaChip(ok: t.slaCumple)),
                          DataCell(
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/ticket-detail',
                                  arguments: {
                                    'id': t.folio,
                                    'title': t.titulo,
                                    'branch': t.sucursal,
                                    'priority': _priorityText(
                                      t.priority,
                                    ).toUpperCase(),
                                    'status': _statusText(t.status),
                                    'createdAt': _fmtDate(t.fecha),
                                    'isTechnician': false,
                                    'category': 'Admin',
                                    'description':
                                        'Detalle pendiente de backend',
                                    'evidences': <Map<String, dynamic>>[],
                                    'comments': <Map<String, String>>[],
                                  },
                                );
                              },
                              child: const Text('Ver'),
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
    );
  }
}

/* ===================== CHIPS & HELPERS ===================== */

class _PriorityChip extends StatelessWidget {
  final AdminTicketPriority priority;
  const _PriorityChip({required this.priority});

  @override
  Widget build(BuildContext context) {
    final c = _priorityColor(priority);
    return Chip(
      label: Text(_priorityText(priority)),
      backgroundColor: c.withOpacity(0.15),
      labelStyle: TextStyle(color: c, fontWeight: FontWeight.w800),
      side: BorderSide(color: c),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
    );
  }
}

class _SlaChip extends StatelessWidget {
  final bool ok;
  const _SlaChip({required this.ok});

  @override
  Widget build(BuildContext context) {
    final c = ok ? const Color(0xFF16A34A) : const Color(0xFFEF4444);
    return Chip(
      label: Text(ok ? 'Cumple' : 'No cumple'),
      backgroundColor: c.withOpacity(0.15),
      labelStyle: TextStyle(color: c, fontWeight: FontWeight.w900),
      side: BorderSide(color: c),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
    );
  }
}

String _statusText(AdminTicketStatus s) {
  switch (s) {
    case AdminTicketStatus.abierto:
      return 'Abierto';
    case AdminTicketStatus.enProceso:
      return 'En proceso';
    case AdminTicketStatus.cerrado:
      return 'Cerrado';
  }
}

String _priorityText(AdminTicketPriority p) {
  switch (p) {
    case AdminTicketPriority.verde:
      return 'Verde';
    case AdminTicketPriority.naranja:
      return 'Naranja';
    case AdminTicketPriority.rojo:
      return 'Rojo';
  }
}

Color _priorityColor(AdminTicketPriority p) {
  switch (p) {
    case AdminTicketPriority.verde:
      return Colors.green;
    case AdminTicketPriority.naranja:
      return Colors.orange;
    case AdminTicketPriority.rojo:
      return Colors.red;
  }
}

String _fmtDate(DateTime d) {
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
