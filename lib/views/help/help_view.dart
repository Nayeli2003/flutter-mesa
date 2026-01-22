import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';

class HelpView extends StatelessWidget {
  const HelpView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayuda'),
      ),

      // Drawer visible también en Ayuda
      drawer: const AppDrawer(
        role: UserRole.sucursal,
        title: 'Sucursal',
        subtitle: 'Mesa de ayuda',
      ),

      // body: resposivo
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth >= 900;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWide ? 900 : double.infinity,
              ),
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 24 : 16,
                  vertical: 16,
                ),
                children: [
                  Text(
                    'Guía rápida',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 10),

                  _InfoCard(
                    icon: Icons.add_circle_outline,
                    title: 'Crear un ticket',
                    subtitle:
                        '1) Entra a “Crear ticket”.\n'
                        '2) Describe el problema.\n'
                        '3) Sube evidencia de tu problema.\n'
                        '4) Envía y guarda tu folio.',
                  ),
                  const SizedBox(height: 12),

                  _InfoCard(
                    icon: Icons.confirmation_number_outlined,
                    title: 'Seguimiento',
                    subtitle:
                        'En “Inicio” puedes ver el estado de tus tickets.\n'
                        'Estados comunes: Abierto, En proceso, Cerrado.',
                  ),

                  const SizedBox(height: 22),
                  Text(
                    'Prioridad (SLA)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 10),

                  const _SlaTile(
                    color: Colors.green,
                    title: 'Verde',
                    subtitle: 'No urgente / Puede esperar.',
                  ),
                  const _SlaTile(
                    color: Colors.orange,
                    title: 'Naranja',
                    subtitle: 'Urgente pero puede esperar.',
                  ),
                  const _SlaTile(
                    color: Colors.red,
                    title: 'Rojo',
                    subtitle: 'Urgente / Atención inmediata.',
                  ),

                  const SizedBox(height: 22),
                  Text(
                    'Preguntas frecuentes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 10),

                  const _FaqTile(
                    question: '¿Quién cierra el ticket?',
                    answer:
                        'Los técnicos cierran el ticket cuando la solución fue aplicada y validada.',
                  ),
                  const _FaqTile(
                    question: '¿Puedo cambiar la prioridad?',
                    answer:
                        'No. Normalmente se mantiene según el análisis.',
                  ),
                  const _FaqTile(
                    question: '¿Qué hago si el problema continúa?',
                    answer:
                        'Agrega un comentario con más detalles o evidencia para que el técnico lo revise.',
                  ),

                  const SizedBox(height: 22),
                  Text(
                    'Contacto',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 10),

                  const _InfoCard(
                    icon: Icons.support_agent,
                    title: 'Mesa de ayuda',
                    subtitle:
                        'Horario: 9:00 a 18:00\n'
                        'Extensión: 123\n'
                        'Correo: soporte@empresa.com',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/* ===================== COMPONENTES ===================== */

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(subtitle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlaTile extends StatelessWidget {
  final Color color;
  final String title;
  final String subtitle;

  const _SlaTile({
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color, radius: 10),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(answer),
          ),
        ],
      ),
    );
  }
}
