import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';

class AdminTasksView extends StatelessWidget {
  const AdminTasksView({super.key});

  @override
  Widget build(BuildContext context) {
    final tickets = [
      {
        "titulo": "Error facturación",
        "sucursal": "Sucursal Centro",
        "estado": "En proceso",
        "tecnico": "Juan",
      },
      {
        "titulo": "Falla internet",
        "sucursal": "Sucursal Norte",
        "estado": "Abierto",
        "tecnico": null,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text("Administrador"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      drawer: const AppDrawer(role: UserRole.admin, title: 'Administrador'),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                /// MÉTRICAS BONITAS
                Row(
                  children: [
                    _metricCard(
                      "Total",
                      20,
                      Colors.blue,
                      Icons.confirmation_number,
                    ),
                    const SizedBox(width: 10),
                    _metricCard("Proceso", 8, Colors.orange, Icons.timelapse),
                    const SizedBox(width: 10),
                    _metricCard(
                      "Cerrados",
                      12,
                      Colors.green,
                      Icons.check_circle,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                /// LISTA
                Expanded(
                  child: ListView.builder(
                    itemCount: tickets.length,
                    itemBuilder: (context, index) =>
                        _adminCard(context, tickets[index]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// =========================
  /// MÉTRICAS
  /// =========================
  Widget _metricCard(String title, int value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 6),
            Text(
              "$value",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  /// =========================
  /// CARD DE TICKET
  /// =========================
  Widget _adminCard(BuildContext context, ticket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TÍTULO
          Text(
            ticket["titulo"],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),

          /// SUCURSAL
          Row(
            children: [
              const Icon(Icons.store, size: 16, color: Colors.black45),
              const SizedBox(width: 6),
              Text(
                ticket["sucursal"],
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),

          const SizedBox(height: 6),

          /// TÉCNICO
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Colors.black45),
              const SizedBox(width: 6),
              Text(
                ticket["tecnico"] ?? "Sin asignar",
                style: TextStyle(
                  color: ticket["tecnico"] == null
                      ? Colors.redAccent
                      : Colors.black87,
                  fontWeight: ticket["tecnico"] == null
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// ACCIONES
          Row(
            children: [
              _statusChip(ticket["estado"]),
              const Spacer(),

              _iconAction(Icons.person_add, Colors.blue, () {}),
              const SizedBox(width: 8),
              _iconAction(Icons.visibility, Colors.grey, () {}),
            ],
          ),
        ],
      ),
    );
  }

  /// =========================
  /// BOTÓN ICONO BONITO
  /// =========================
  Widget _iconAction(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  /// =========================
  /// STATUS CHIP
  /// =========================
  Widget _statusChip(String status) {
    Color color;

    switch (status) {
      case "En proceso":
        color = Colors.orange;
        break;
      case "Abierto":
        color = Colors.redAccent;
        break;
      default:
        color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
