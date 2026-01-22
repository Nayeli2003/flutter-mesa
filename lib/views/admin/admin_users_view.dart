import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';

enum AdminUserRole { admin, tecnico, sucursal }

class AdminUserModel {
  final String id;
  String nombre;

  // credenciales
  String username;
  String password;

  AdminUserRole rol;

  // Solo si es sucursal
  String? branchId;
  String? sucursal;

  bool activo;

  AdminUserModel({
    required this.id,
    required this.nombre,
    required this.username,
    required this.password,
    required this.rol,
    this.branchId,
    this.sucursal,
    required this.activo,
  });
}

class AdminUsersView extends StatefulWidget {
  const AdminUsersView({super.key});

  @override
  State<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<AdminUsersView>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  // filtros por tab
  final TextEditingController _searchAdminCtrl = TextEditingController();
  final TextEditingController _searchTechCtrl = TextEditingController();
  final TextEditingController _searchBranchCtrl = TextEditingController();

  bool? _activeAdmin;
  bool? _activeTech;
  bool? _activeBranch;

  final List<AdminUserModel> _users = [
    AdminUserModel(
      id: 'USR-001',
      nombre: 'Admin Principal',
      username: 'admin',
      password: '123456',
      rol: AdminUserRole.admin,
      activo: true,
    ),
    AdminUserModel(
      id: 'USR-002',
      nombre: 'Juan Pérez',
      username: 'juan.perez',
      password: '123456',
      rol: AdminUserRole.tecnico,
      activo: true,
    ),
    AdminUserModel(
      id: 'USR-003',
      nombre: 'Ana López',
      username: 'ana.lopez',
      password: '123456',
      rol: AdminUserRole.tecnico,
      activo: false,
    ),
    AdminUserModel(
      id: 'USR-004',
      nombre: 'Sucursal Centro',
      username: 'suc.centro',
      password: '123456',
      rol: AdminUserRole.sucursal,
      branchId: 'SUC-001',
      sucursal: 'Sucursal Centro',
      activo: true,
    ),
    AdminUserModel(
      id: 'USR-005',
      nombre: 'Sucursal Norte',
      username: 'suc.norte',
      password: '123456',
      rol: AdminUserRole.sucursal,
      branchId: 'SUC-002',
      sucursal: 'Sucursal Norte',
      activo: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchAdminCtrl.dispose();
    _searchTechCtrl.dispose();
    _searchBranchCtrl.dispose();
    super.dispose();
  }

  // eliminar (solo inactivos)
  Future<void> _deleteUser(AdminUserModel user) async {
    if (user.activo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes eliminar un usuario activo.')),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text(
          '¿Seguro que deseas eliminar a:\n\n'
          '${user.nombre} (${user.username})?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok == true) {
      setState(() {
        _users.removeWhere((x) => x.id == user.id);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Usuario eliminado')));
    }
  }

  String _roleText(AdminUserRole r) {
    switch (r) {
      case AdminUserRole.admin:
        return 'Admin';
      case AdminUserRole.tecnico:
        return 'Técnico';
      case AdminUserRole.sucursal:
        return 'Sucursal';
    }
  }

  IconData _roleIcon(AdminUserRole r) {
    switch (r) {
      case AdminUserRole.admin:
        return Icons.admin_panel_settings;
      case AdminUserRole.tecnico:
        return Icons.engineering;
      case AdminUserRole.sucursal:
        return Icons.store;
    }
  }

  Color _roleColor(AdminUserRole r) {
    switch (r) {
      case AdminUserRole.admin:
        return const Color(0xFF2563EB);
      case AdminUserRole.tecnico:
        return const Color(0xFFF59E0B);
      case AdminUserRole.sucursal:
        return const Color(0xFF10B981);
    }
  }

  void _clearAdminFilters() {
    setState(() {
      _searchAdminCtrl.clear();
      _activeAdmin = null;
    });
  }

  void _clearTechFilters() {
    setState(() {
      _searchTechCtrl.clear();
      _activeTech = null;
    });
  }

  void _clearBranchFilters() {
    setState(() {
      _searchBranchCtrl.clear();
      _activeBranch = null;
    });
  }

  int _nextId() => _users.length + 1;

  // ===== MODAL ADMIN =====
  Future<void> _openAdminModal({AdminUserModel? user}) async {
    final isEdit = user != null;

    final nombreCtrl = TextEditingController(text: isEdit ? user.nombre : '');
    final usernameCtrl = TextEditingController(
      text: isEdit ? user.username : '',
    );
    final passwordCtrl = TextEditingController(
      text: isEdit ? user.password : '',
    );
    bool activo = isEdit ? user.activo : true;

    bool showPass = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(
                isEdit ? 'Editar administrador' : 'Agregar administrador',
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nombreCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: usernameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Usuario',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passwordCtrl,
                        obscureText: !showPass,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setLocal(() => showPass = !showPass),
                            icon: Icon(
                              showPass
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: activo,
                        onChanged: (v) => setLocal(() => activo = v),
                        title: const Text('Activo'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final nombre = nombreCtrl.text.trim();
                    final username = usernameCtrl.text.trim();
                    final pass = passwordCtrl.text;

                    if (nombre.isEmpty || username.isEmpty || pass.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Nombre, usuario y contraseña son obligatorios.',
                          ),
                        ),
                      );
                      return;
                    }

                    if (isEdit) {
                      user!.nombre = nombre;
                      user.username = username;
                      user.password = pass;
                      user.activo = activo;
                    } else {
                      _users.add(
                        AdminUserModel(
                          id: 'USR-${_nextId().toString().padLeft(3, '0')}',
                          nombre: nombre,
                          username: username,
                          password: pass,
                          rol: AdminUserRole.admin,
                          activo: activo,
                        ),
                      );
                    }

                    Navigator.pop(context, true);
                  },
                  child: Text(isEdit ? 'Guardar' : 'Agregar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok == true) setState(() {});
  }

  // ===== MODAL TECNICO =====
  Future<void> _openTechModal({AdminUserModel? user}) async {
    final isEdit = user != null;

    final nombreCtrl = TextEditingController(text: isEdit ? user.nombre : '');
    final usernameCtrl = TextEditingController(
      text: isEdit ? user.username : '',
    );
    final passwordCtrl = TextEditingController(
      text: isEdit ? user.password : '',
    );
    bool activo = isEdit ? user.activo : true;

    bool showPass = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(isEdit ? 'Editar técnico' : 'Agregar técnico'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nombreCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: usernameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Usuario',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passwordCtrl,
                        obscureText: !showPass,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setLocal(() => showPass = !showPass),
                            icon: Icon(
                              showPass
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: activo,
                        onChanged: (v) => setLocal(() => activo = v),
                        title: const Text('Activo'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final nombre = nombreCtrl.text.trim();
                    final username = usernameCtrl.text.trim();
                    final pass = passwordCtrl.text;

                    if (nombre.isEmpty || username.isEmpty || pass.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Nombre, usuario y contraseña son obligatorios.',
                          ),
                        ),
                      );
                      return;
                    }

                    if (isEdit) {
                      user!.nombre = nombre;
                      user.username = username;
                      user.password = pass;
                      user.activo = activo;
                    } else {
                      _users.add(
                        AdminUserModel(
                          id: 'USR-${_nextId().toString().padLeft(3, '0')}',
                          nombre: nombre,
                          username: username,
                          password: pass,
                          rol: AdminUserRole.tecnico,
                          activo: activo,
                        ),
                      );
                    }

                    Navigator.pop(context, true);
                  },
                  child: Text(isEdit ? 'Guardar' : 'Agregar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok == true) setState(() {});
  }

  // ===== MODAL SUCURSAL =====
  Future<void> _openBranchModal({AdminUserModel? user}) async {
    final isEdit = user != null;

    final branchIdCtrl = TextEditingController(
      text: isEdit ? (user.branchId ?? '') : '',
    );
    final sucursalCtrl = TextEditingController(
      text: isEdit ? (user.sucursal ?? '') : '',
    );
    final usernameCtrl = TextEditingController(
      text: isEdit ? user.username : '',
    );
    final passwordCtrl = TextEditingController(
      text: isEdit ? user.password : '',
    );
    bool activo = isEdit ? user.activo : true;

    bool showPass = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(isEdit ? 'Editar sucursal' : 'Agregar sucursal'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: branchIdCtrl,
                        decoration: const InputDecoration(
                          labelText: 'ID Sucursal',
                          prefixIcon: Icon(Icons.tag),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: sucursalCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de sucursal',
                          prefixIcon: Icon(Icons.store),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: usernameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Usuario',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passwordCtrl,
                        obscureText: !showPass,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setLocal(() => showPass = !showPass),
                            icon: Icon(
                              showPass
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: activo,
                        onChanged: (v) => setLocal(() => activo = v),
                        title: const Text('Activo'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final bid = branchIdCtrl.text.trim();
                    final suc = sucursalCtrl.text.trim();
                    final username = usernameCtrl.text.trim();
                    final pass = passwordCtrl.text;

                    if (bid.isEmpty ||
                        suc.isEmpty ||
                        username.isEmpty ||
                        pass.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Todos los campos son obligatorios.'),
                        ),
                      );
                      return;
                    }

                    if (isEdit) {
                      user!.branchId = bid;
                      user.sucursal = suc;
                      user.nombre = suc;
                      user.username = username;
                      user.password = pass;
                      user.activo = activo;
                    } else {
                      _users.add(
                        AdminUserModel(
                          id: 'USR-${_nextId().toString().padLeft(3, '0')}',
                          nombre: suc,
                          username: username,
                          password: pass,
                          rol: AdminUserRole.sucursal,
                          branchId: bid,
                          sucursal: suc,
                          activo: activo,
                        ),
                      );
                    }

                    Navigator.pop(context, true);
                  },
                  child: Text(isEdit ? 'Guardar' : 'Agregar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok == true) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final admins = _users.where((u) => u.rol == AdminUserRole.admin).toList();
    final technicians = _users
        .where((u) => u.rol == AdminUserRole.tecnico)
        .toList();
    final branches = _users
        .where((u) => u.rol == AdminUserRole.sucursal)
        .toList();

    // filtros: admins
    List<AdminUserModel> adminFiltered = admins;
    final aq = _searchAdminCtrl.text.trim().toLowerCase();
    if (aq.isNotEmpty) {
      adminFiltered = adminFiltered.where((u) {
        return u.id.toLowerCase().contains(aq) ||
            u.nombre.toLowerCase().contains(aq) ||
            u.username.toLowerCase().contains(aq);
      }).toList();
    }
    if (_activeAdmin != null) {
      adminFiltered = adminFiltered
          .where((u) => u.activo == _activeAdmin)
          .toList();
    }

    // filtros: tecnicos
    List<AdminUserModel> techFiltered = technicians;
    final tq = _searchTechCtrl.text.trim().toLowerCase();
    if (tq.isNotEmpty) {
      techFiltered = techFiltered.where((u) {
        return u.id.toLowerCase().contains(tq) ||
            u.nombre.toLowerCase().contains(tq) ||
            u.username.toLowerCase().contains(tq);
      }).toList();
    }
    if (_activeTech != null) {
      techFiltered = techFiltered
          .where((u) => u.activo == _activeTech)
          .toList();
    }

    // filtros: sucursales
    List<AdminUserModel> branchFiltered = branches;
    final bq = _searchBranchCtrl.text.trim().toLowerCase();
    if (bq.isNotEmpty) {
      branchFiltered = branchFiltered.where((u) {
        return u.id.toLowerCase().contains(bq) ||
            (u.branchId ?? '').toLowerCase().contains(bq) ||
            (u.sucursal ?? '').toLowerCase().contains(bq) ||
            u.username.toLowerCase().contains(bq);
      }).toList();
    }
    if (_activeBranch != null) {
      branchFiltered = branchFiltered
          .where((u) => u.activo == _activeBranch)
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.admin_panel_settings), text: 'Admins'),
            Tab(icon: Icon(Icons.engineering), text: 'Técnicos'),
            Tab(icon: Icon(Icons.store), text: 'Sucursales'),
          ],
        ),
        actions: [
          AnimatedBuilder(
            animation: _tab,
            builder: (context, _) {
              final idx = _tab.index;
              return IconButton(
                tooltip: idx == 0
                    ? 'Agregar admin'
                    : idx == 1
                    ? 'Agregar técnico'
                    : 'Agregar sucursal',
                onPressed: () {
                  if (idx == 0) _openAdminModal();
                  if (idx == 1) _openTechModal();
                  if (idx == 2) _openBranchModal();
                },
                icon: Icon(
                  idx == 0
                      ? Icons.person_add_alt_1
                      : idx == 1
                      ? Icons.person_add_alt_1
                      : Icons.add_business,
                ),
              );
            },
          ),
        ],
      ),
      drawer: const AppDrawer(
        role: UserRole.admin,
        title: 'Admin',
        subtitle: 'Mesa de ayuda',
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          return TabBarView(
            controller: _tab,
            children: [
              // ADMINS
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _TabFiltersBar(
                      searchCtrl: _searchAdminCtrl,
                      active: _activeAdmin,
                      onActiveChanged: (v) => setState(() => _activeAdmin = v),
                      onClear: _clearAdminFilters,
                      onChanged: () => setState(() {}),
                      primaryLabel: 'Agregar admin',
                      primaryIcon: Icons.person_add_alt_1,
                      onPrimary: () => _openAdminModal(),
                      hint: 'Buscar (nombre, usuario, id)',
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: isWide
                          ? _UsersTable(
                              users: adminFiltered,
                              roleText: _roleText,
                              roleIcon: _roleIcon,
                              roleColor: _roleColor,
                              onEdit: (u) => _openAdminModal(user: u),
                              onToggleActive: (u) =>
                                  setState(() => u.activo = !u.activo),
                              onDelete: (u) => _deleteUser(u),
                            )
                          : _UsersCards(
                              users: adminFiltered,
                              roleText: _roleText,
                              roleIcon: _roleIcon,
                              roleColor: _roleColor,
                              onEdit: (u) => _openAdminModal(user: u),
                              onToggleActive: (u) =>
                                  setState(() => u.activo = !u.activo),
                              onDelete: (u) => _deleteUser(u),
                            ),
                    ),
                  ],
                ),
              ),

              // TÉCNICOS
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _TabFiltersBar(
                      searchCtrl: _searchTechCtrl,
                      active: _activeTech,
                      onActiveChanged: (v) => setState(() => _activeTech = v),
                      onClear: _clearTechFilters,
                      onChanged: () => setState(() {}),
                      primaryLabel: 'Agregar técnico',
                      primaryIcon: Icons.person_add_alt_1,
                      onPrimary: () => _openTechModal(),
                      hint: 'Buscar (nombre, usuario, id)',
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: isWide
                          ? _UsersTable(
                              users: techFiltered,
                              roleText: _roleText,
                              roleIcon: _roleIcon,
                              roleColor: _roleColor,
                              onEdit: (u) => _openTechModal(user: u),
                              onToggleActive: (u) =>
                                  setState(() => u.activo = !u.activo),
                              onDelete: (u) => _deleteUser(u),
                            )
                          : _UsersCards(
                              users: techFiltered,
                              roleText: _roleText,
                              roleIcon: _roleIcon,
                              roleColor: _roleColor,
                              onEdit: (u) => _openTechModal(user: u),
                              onToggleActive: (u) =>
                                  setState(() => u.activo = !u.activo),
                              onDelete: (u) => _deleteUser(u),
                            ),
                    ),
                  ],
                ),
              ),

              // SUCURSALES
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _TabFiltersBar(
                      searchCtrl: _searchBranchCtrl,
                      active: _activeBranch,
                      onActiveChanged: (v) => setState(() => _activeBranch = v),
                      onClear: _clearBranchFilters,
                      onChanged: () => setState(() {}),
                      primaryLabel: 'Agregar sucursal',
                      primaryIcon: Icons.add_business,
                      onPrimary: () => _openBranchModal(),
                      hint: 'Buscar (id sucursal, nombre, usuario, id)',
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: isWide
                          ? _UsersTable(
                              users: branchFiltered,
                              roleText: _roleText,
                              roleIcon: _roleIcon,
                              roleColor: _roleColor,
                              onEdit: (u) => _openBranchModal(user: u),
                              onToggleActive: (u) =>
                                  setState(() => u.activo = !u.activo),
                              onDelete: (u) => _deleteUser(u),
                            )
                          : _UsersCards(
                              users: branchFiltered,
                              roleText: _roleText,
                              roleIcon: _roleIcon,
                              roleColor: _roleColor,
                              onEdit: (u) => _openBranchModal(user: u),
                              onToggleActive: (u) =>
                                  setState(() => u.activo = !u.activo),
                              onDelete: (u) => _deleteUser(u),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/* ===================== FILTER BAR (TAB) ===================== */

class _TabFiltersBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final bool? active;

  final ValueChanged<bool?> onActiveChanged;
  final VoidCallback onClear;
  final VoidCallback onChanged;

  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onPrimary;

  final String hint;

  const _TabFiltersBar({
    required this.searchCtrl,
    required this.active,
    required this.onActiveChanged,
    required this.onClear,
    required this.onChanged,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimary,
    required this.hint,
  });

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
                  width: isWide ? 420 : double.infinity,
                  child: TextField(
                    controller: searchCtrl,
                    onChanged: (_) => onChanged(),
                    decoration: InputDecoration(
                      labelText: hint,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: isWide ? 240 : double.infinity,
                  child: DropdownButtonFormField<bool>(
                    value: active,
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text('Estado: Todos'),
                      ),
                      DropdownMenuItem(value: true, child: Text('Activos')),
                      DropdownMenuItem(value: false, child: Text('Inactivos')),
                    ],
                    onChanged: onActiveChanged,
                    decoration: InputDecoration(
                      labelText: 'Estado',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
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
                SizedBox(
                  width: isWide ? 220 : double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onPrimary,
                    icon: Icon(primaryIcon),
                    label: Text(primaryLabel),
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

class _UsersCards extends StatelessWidget {
  final List<AdminUserModel> users;
  final String Function(AdminUserRole) roleText;
  final IconData Function(AdminUserRole) roleIcon;
  final Color Function(AdminUserRole) roleColor;

  final void Function(AdminUserModel) onEdit;
  final void Function(AdminUserModel) onToggleActive;
  final void Function(AdminUserModel) onDelete;

  const _UsersCards({
    required this.users,
    required this.roleText,
    required this.roleIcon,
    required this.roleColor,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const Center(child: Text('No hay usuarios para mostrar.'));
    }

    return ListView.separated(
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final u = users[index];
        final c = roleColor(u.rol);

        final extra = u.rol == AdminUserRole.sucursal
            ? '\n${u.branchId ?? ""} • ${u.sucursal ?? ""}'
            : '';

        final passMasked = '•' * (u.password.length.clamp(6, 12));

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: c.withOpacity(0.15),
              child: Icon(roleIcon(u.rol), color: c),
            ),
            title: Text(
              '${u.nombre} • ${u.id}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              'Usuario: ${u.username}\n'
              'Contraseña: $passMasked\n'
              '${roleText(u.rol)} • ${u.activo ? "Activo" : "Inactivo"}$extra',
            ),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') onEdit(u);
                if (v == 'toggle') onToggleActive(u);
                if (v == 'delete') onDelete(u);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(u.activo ? 'Desactivar' : 'Activar'),
                ),
                if (!u.activo)
                  const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              ],
            ),
          ),
        );
      },
    );
  }
}

/* ===================== WEB/DESKTOP: TABLE ===================== */

class _UsersTable extends StatefulWidget {
  final List<AdminUserModel> users;

  final String Function(AdminUserRole) roleText;
  final IconData Function(AdminUserRole) roleIcon;
  final Color Function(AdminUserRole) roleColor;

  final void Function(AdminUserModel) onEdit;
  final void Function(AdminUserModel) onToggleActive;
  final void Function(AdminUserModel) onDelete;

  const _UsersTable({
    required this.users,
    required this.roleText,
    required this.roleIcon,
    required this.roleColor,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  State<_UsersTable> createState() => _UsersTableState();
}

class _UsersTableState extends State<_UsersTable> {
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
    if (widget.users.isEmpty) {
      return const Center(child: Text('No hay usuarios para mostrar.'));
    }

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
              constraints: const BoxConstraints(minWidth: 1200),
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
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Nombre')),
                      DataColumn(label: Text('Usuario')),
                      DataColumn(label: Text('Rol')),
                      DataColumn(label: Text('Sucursal')),
                      DataColumn(label: Text('Estado')),
                      DataColumn(label: Text('Acción')),
                    ],
                    rows: widget.users.map((u) {
                      final c = widget.roleColor(u.rol);
                      final suc = u.rol == AdminUserRole.sucursal
                          ? '${u.branchId ?? ""} • ${u.sucursal ?? ""}'
                          : '—';

                      return DataRow(
                        cells: [
                          DataCell(Text(u.id)),
                          DataCell(Text(u.nombre)),
                          DataCell(Text(u.username)),
                          DataCell(
                            Row(
                              children: [
                                Icon(
                                  widget.roleIcon(u.rol),
                                  size: 16,
                                  color: c,
                                ),
                                const SizedBox(width: 6),
                                Text(widget.roleText(u.rol)),
                              ],
                            ),
                          ),
                          DataCell(Text(suc)),
                          DataCell(Text(u.activo ? 'Activo' : 'Inactivo')),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Editar',
                                  onPressed: () => widget.onEdit(u),
                                  icon: const Icon(Icons.edit),
                                ),
                                IconButton(
                                  tooltip: u.activo ? 'Desactivar' : 'Activar',
                                  onPressed: () => widget.onToggleActive(u),
                                  icon: Icon(
                                    u.activo ? Icons.block : Icons.check_circle,
                                    color: u.activo
                                        ? Colors.orange
                                        : Colors.green,
                                  ),
                                ),
                                if (!u.activo)
                                  IconButton(
                                    tooltip: 'Eliminar',
                                    onPressed: () => widget.onDelete(u),
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                  ),
                              ],
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
