import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';

class TechnicianTasksView extends StatelessWidget {
  const TechnicianTasksView({super.key});

  @override
  Widget build(BuildContext context) {
    final tickets = [
      {
        "titulo": "Error en sistema",
        "sucursal": "Bodega 512",
        "estado": "En proceso",
      },
      {"titulo": "Falla de red", "sucursal": "Bodega 120", "estado": "Abierto"},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text("Técnico"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      drawer: const AppDrawer(role: UserRole.tecnico, title: 'Técnico'),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                /// MÉTRICAS PRO
                Row(
                  children: [
                    _metricCard(
                      "Asignados",
                      tickets.length,
                      Colors.blue,
                      Icons.build,
                    ),
                    const SizedBox(width: 12),
                    _metricCard("Urgentes", 1, Colors.red, Icons.priority_high),
                  ],
                ),

                const SizedBox(height: 20),

                /// LISTA
                Expanded(
                  child: ListView.builder(
                    itemCount: tickets.length,
                    itemBuilder: (context, index) =>
                        _ticketCard(context, tickets[index]),
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
  /// MÉTRICAS BONITAS
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Text(
                  "$value",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// =========================
  /// CARD DE TICKET
  /// =========================
  Widget _ticketCard(BuildContext context, ticket) {
    final status = ticket["estado"];

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
      child: Row(
        children: [
          /// ICONO
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.build, color: Colors.blue),
          ),

          const SizedBox(width: 14),

          /// INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket["titulo"],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  ticket["sucursal"],
                  style: const TextStyle(color: Colors.black54),
                ),

                const SizedBox(height: 8),

                _statusChip(status),
              ],
            ),
          ),

          /// ACCIÓN
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  /// =========================
  /// STATUS CHIP PRO
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
