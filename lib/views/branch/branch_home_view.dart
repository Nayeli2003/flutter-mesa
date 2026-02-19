import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../widgets/app_drawer.dart';
import '../../services/session.dart'; // 👈 ajusta si tu Session está en otro lado

class BranchHomeView extends StatefulWidget {
  const BranchHomeView({super.key});

  @override
  State<BranchHomeView> createState() => _BranchHomeViewState();
}

class _BranchHomeViewState extends State<BranchHomeView> {

  List<dynamic> tickets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarTickets();
  }

  Future<void> _cargarTickets() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/tickets'),
        headers: {
          'Authorization': 'Bearer ${Session.token}',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          tickets = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Color _priorityColor(String? color) {
    switch (color) {
      case 'red':
        return const Color(0xFFEF4444);
      case 'orange':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF4CAF50);
    }
  }

  @override
  Widget build(BuildContext context) {

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
      drawer: const AppDrawer(role: UserRole.sucursal, title: 'Sucursal'),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final bool isDesktop = width >= 1024;
                final bool isTablet = width >= 600 && width < 1024;
                final double contentMaxWidth =
                    isDesktop ? 900 : (isTablet ? 650 : double.infinity);

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: Column(
                      children: [

                        // RESUMEN
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
                                  value: '${tickets.where((t) => t['estado'] == 'Abierto').length}',
                                  color: const Color(0xFFEF4444),
                                ),
                              ),
                              if (!(!isTablet && !isDesktop)) ...[
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _MiniPill(
                                    label: 'En proceso',
                                    value: '${tickets.where((t) => t['estado'] == 'En proceso').length}',
                                    color: const Color(0xFFF59E0B),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // LISTA
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                            itemCount: tickets.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {

                              final t = tickets[index];

                              final String id =
                                  t['id_ticket'].toString();

                              final String title =
                                  t['titulo'] ?? '';

                              final String status =
                                  t['estado'] ?? '';

                              final String prioridadColor =
                                  t['prioridad_color'] ?? 'green';

                              final Color pColor =
                                  _priorityColor(prioridadColor);

                              return Container(
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
                                    Container(
                                      width: 10,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: pColor,
                                        borderRadius:
                                            BorderRadius.circular(12),
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
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 14.5,
                                                    fontWeight: FontWeight.w800,
                                                    color:
                                                        Color(0xFF111827),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              _StatusChip(status: status),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'TCK-$id',
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.pushNamed(context, '/create-ticket')
              .then((_) => _cargarTickets());
        },
        icon: const Icon(Icons.add),
        label: const Text('Crear ticket'),
      ),
    );
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
