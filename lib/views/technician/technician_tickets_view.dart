import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';

enum TicketStatus { asignado, enProceso, cerrado }
enum TicketPriority { verde, naranja, rojo }

class TicketModel {
  final String folio;
  final String titulo;
  final String sucursal;
  final String branchId; // ID Sucursal
  final DateTime fecha;  // Fecha
  final TicketStatus status;
  final TicketPriority priority;

  const TicketModel({
    required this.folio,
    required this.titulo,
    required this.sucursal,
    required this.branchId,
    required this.fecha,
    required this.status,
    required this.priority,
  });
}

class TechnicianTicketsView extends StatefulWidget {
  final String title;
  final TicketStatus? statusFilter;

  const TechnicianTicketsView({
    super.key,
    required this.title,
    this.statusFilter,
  });

  @override
  State<TechnicianTicketsView> createState() => _TechnicianTicketsViewState();
}

class _TechnicianTicketsViewState extends State<TechnicianTicketsView> {
  final TextEditingController _searchCtrl = TextEditingController();

  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool get _isClosedScreen => widget.statusFilter == TicketStatus.cerrado;

  // Datos de ejemplo (luego se conecta al backend)
  List<TicketModel> _ticketsFake() => [
        TicketModel(
          folio: 'TK-001',
          titulo: 'No abre sistema',
          sucursal: 'Sucursal Centro',
          branchId: 'SUC-001',
          fecha: DateTime(2026, 1, 14, 10, 30),
          status: TicketStatus.asignado,
          priority: TicketPriority.rojo,
        ),
        TicketModel(
          folio: 'TK-002',
          titulo: 'Impresora no imprime',
          sucursal: 'Sucursal Norte',
          branchId: 'SUC-002',
          fecha: DateTime(2026, 1, 14, 13, 10),
          status: TicketStatus.enProceso,
          priority: TicketPriority.naranja,
        ),
        TicketModel(
          folio: 'TK-003',
          titulo: 'Actualización aplicada',
          sucursal: 'Sucursal Sur',
          branchId: 'SUC-003',
          fecha: DateTime(2026, 1, 13, 9, 5),
          status: TicketStatus.cerrado,
          priority: TicketPriority.verde,
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
      _fromDate = null;
      _toDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final all = _ticketsFake();

    // 1) filtro por status según pantalla
    final base = widget.statusFilter == null
        ? all.where((t) => t.status != TicketStatus.cerrado).toList() // Dashboard: no cerrados
        : all.where((t) => t.status == widget.statusFilter).toList();

    // 2) filtro buscador (solo en cerrados)
    final q = _searchCtrl.text.trim().toLowerCase();
    List<TicketModel> filtered = base;

    if (_isClosedScreen && q.isNotEmpty) {
      filtered = filtered.where((t) {
        return t.folio.toLowerCase().contains(q) ||
            t.titulo.toLowerCase().contains(q) ||
            t.sucursal.toLowerCase().contains(q) ||
            t.branchId.toLowerCase().contains(q);
      }).toList();
    }

    // 3) filtro por fechas (solo en cerrados)
    if (_isClosedScreen && (_fromDate != null || _toDate != null)) {
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
      appBar: AppBar(title: Text(widget.title)),
      drawer: const AppDrawer(
        role: UserRole.tecnico,
        title: 'technician',
        subtitle: 'Mesa de ayuda',
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 1100 : double.infinity),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Barra de filtros SOLO en cerrados
                    if (_isClosedScreen) ...[
                      _ClosedFiltersBar(
                        searchCtrl: _searchCtrl,
                        fromDate: _fromDate,
                        toDate: _toDate,
                        onPickFrom: _pickFromDate,
                        onPickTo: _pickToDate,
                        onClear: _clearFilters,
                        onChanged: () => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                    ],

                    Expanded(
                      child: isWide
                          ? _TicketsTable(tickets: filtered)
                          : _TicketsCards(tickets: filtered),
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

/* ===================== FILTROS CERRADOS ===================== */

class _ClosedFiltersBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final DateTime? fromDate;
  final DateTime? toDate;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onClear;
  final VoidCallback onChanged;

  const _ClosedFiltersBar({
    required this.searchCtrl,
    required this.fromDate,
    required this.toDate,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onClear,
    required this.onChanged,
  });

  String _fmt(DateTime? d) {
    if (d == null) return '—';
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, c) {
            final isWide = c.maxWidth >= 900;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: isWide ? 360 : double.infinity,
                  child: TextField(
                    controller: searchCtrl,
                    onChanged: (_) => onChanged(),
                    decoration: InputDecoration(
                      labelText: 'Buscar (folio, título, sucursal, id sucursal)',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                SizedBox(
                  width: isWide ? 200 : double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onPickFrom,
                    icon: const Icon(Icons.date_range),
                    label: Text('Desde: ${_fmt(fromDate)}'),
                  ),
                ),
                SizedBox(
                  width: isWide ? 200 : double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onPickTo,
                    icon: const Icon(Icons.date_range),
                    label: Text('Hasta: ${_fmt(toDate)}'),
                  ),
                ),
                SizedBox(
                  width: isWide ? 140 : double.infinity,
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

class _TicketsCards extends StatelessWidget {
  final List<TicketModel> tickets;
  const _TicketsCards({required this.tickets});

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
              '${t.branchId} • ${t.sucursal}\n'
              '${_statusText(t.status)} • ${_fmtDate(t.fecha)}',
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Usa tu ticket_detail_view.dart (ajusta la ruta si ya tienes otra)
              Navigator.pushNamed(context, '/ticket-detail', arguments: {
                'id': t.folio,
                'title': t.titulo,
                'branch': t.sucursal,
                'priority': _priorityText(t.priority).toUpperCase(),
                'status': _statusText(t.status),
                'createdAt': _fmtDate(t.fecha),
                'role': 'tecnico',
                'category': 'Soporte',
                'description': 'Detalle pendiente de backend',
                'evidences': <Map<String, dynamic>>[],
                'comments': <Map<String, String>>[],
              });
            },
          ),
        );
      },
    );
  }
}

/* ===================== WEB/DESKTOP: TABLE ===================== */

class _TicketsTable extends StatelessWidget {
  final List<TicketModel> tickets;
  const _TicketsTable({required this.tickets});

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) {
      return const Center(child: Text('No hay tickets para mostrar.'));
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Folio')),
            DataColumn(label: Text('Título')),
            DataColumn(label: Text('ID Sucursal')), // nuevo
            DataColumn(label: Text('Sucursal')),
            DataColumn(label: Text('Fecha')),       // nuevo
            DataColumn(label: Text('Estado')),
            DataColumn(label: Text('Prioridad')),
            DataColumn(label: Text('Acción')),
          ],
          rows: tickets.map((t) {
            return DataRow(
              cells: [
                DataCell(Text(t.folio)),
                DataCell(Text(t.titulo)),
                DataCell(Text(t.branchId)),
                DataCell(Text(t.sucursal)),
                DataCell(Text(_fmtDate(t.fecha))),
                DataCell(Text(_statusText(t.status))),
                DataCell(_PriorityChip(priority: t.priority)),
                DataCell(
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/ticket-detail', arguments: {
                        'id': t.folio,
                        'title': t.titulo,
                        'branch': t.sucursal,
                        'priority': _priorityText(t.priority).toUpperCase(),
                        'status': _statusText(t.status),
                        'createdAt': _fmtDate(t.fecha),
                        'role': 'tecnico',
                        'category': 'Soporte',
                        'description': 'Detalle pendiente de backend',
                        'evidences': <Map<String, dynamic>>[],
                        'comments': <Map<String, String>>[],
                      });
                    },
                    child: const Text('Ver'),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

/* ===================== UI HELPERS ===================== */

class _PriorityChip extends StatelessWidget {
  final TicketPriority priority;
  const _PriorityChip({required this.priority});

  @override
  Widget build(BuildContext context) {
    final c = _priorityColor(priority);
    return Chip(
      label: Text(_priorityText(priority)),
      backgroundColor: c.withOpacity(0.15),
      labelStyle: TextStyle(color: c, fontWeight: FontWeight.w800),
      side: BorderSide(color: c),
    );
  }
}

String _statusText(TicketStatus s) {
  switch (s) {
    case TicketStatus.asignado:
      return 'Asignado';
    case TicketStatus.enProceso:
      return 'En proceso';
    case TicketStatus.cerrado:
      return 'Cerrado';
  }
}

String _priorityText(TicketPriority p) {
  switch (p) {
    case TicketPriority.verde:
      return 'Verde';
    case TicketPriority.naranja:
      return 'Naranja';
    case TicketPriority.rojo:
      return 'Rojo';
  }
}

Color _priorityColor(TicketPriority p) {
  switch (p) {
    case TicketPriority.verde:
      return Colors.green;
    case TicketPriority.naranja:
      return Colors.orange;
    case TicketPriority.rojo:
      return Colors.red;
  }
}

String _fmtDate(DateTime d) {
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
