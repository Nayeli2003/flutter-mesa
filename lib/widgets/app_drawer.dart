import 'package:flutter/material.dart';

enum UserRole {admin, tecnico, sucursal }

class AppDrawer extends StatelessWidget {
  final UserRole role;
  final String title; //ya sea admin, sucursal, tecnico
  final String subtitle; //mesa de ayuda 

  const AppDrawer({
    super.key,
    required this.role,
    required this.title,
    this.subtitle = 'Mesa de ayuda',
  });

  @override
  Widget build(BuildContext context) {
    // TODO: implement build

    final items =  _menuItemsForRole(role);

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
            ),
            child: Row(
                children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 32, color: Color(0xFF4CAF50)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$title\n$subtitle',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Opciones según rol
          ...items.map(
            (i) => _DrawerItem(
              icon: i.icon,
              text: i.label,
              onTap: () {
                Navigator.pop(context); // cerrar drawer
                if (i.route != null) {
                  Navigator.pushReplacementNamed(context, i.route!);
                } else {
                  i.onTap?.call();
                }
              },
            ),
          ),

          const Spacer(),
          const Divider(),

          _DrawerItem(
            icon: Icons.logout,
            text: 'Cerrar sesión',
            color: Colors.red,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  List<_MenuItem> _menuItemsForRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const [
          _MenuItem(Icons.home, 'Dashboard', route: '/admin'),
          _MenuItem(Icons.group, 'Usuarios', route: '/admin-users'),
          _MenuItem(Icons.bar_chart, 'Métricas / SLA', route: '/admin-metrics'),
          _MenuItem(Icons.confirmation_number, 'Todos los tickets', route: '/admin-tickets'),
        ];

      case UserRole.tecnico:
        return const [
          _MenuItem(Icons.home, 'Dashboard', route: '/technician'),
          _MenuItem(Icons.play_circle, 'En proceso', route: '/tech-inprogress'),
          _MenuItem(Icons.check_circle, 'Cerrados', route: '/tech-closed'),
        ];


      case UserRole.sucursal:
        return const [
          _MenuItem(Icons.home, 'Inicio', route: '/branch'),
          _MenuItem(Icons.add, 'Crear ticket', route: '/create-ticket'),
          _MenuItem(Icons.help_outline, 'Ayuda', route: '/help'),
        ];
    }
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String? route;
  final VoidCallback? onTap;

  const _MenuItem(this.icon, this.label, {this.route, this.onTap});
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem({
    required this.icon,
    required this.text,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xFF374151)),
      title: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color ?? const Color(0xFF374151),
        ),
      ),
      onTap: onTap,
    );
  }
}
