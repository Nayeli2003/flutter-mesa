import 'dart:convert';
import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../widgets/app_drawer.dart';
import 'package:mesa_sana/services/session.dart';

const List<String> kSucursales = [
  'Tezontepec',
  'Tecámac centro',
  'Tecámac la Principal',
  'Tecámac Presidencia',
  'CD Cuauhtemoc',
  'Ojo de Agua',
  'Ceda 512',
  'Ceda 517',
  'Jardines de Morelos 1',
  'Nuevo Laredo',
  'Via Morelos',
  'San Cristobal',
  'San Pablo',
  'Izcalli',
  'CD Azteca 1',
  'Casas Aleman',
  'Zacatengo',
  'Centro Historico',
  'Neza',
  'Ceda E21',
  'Cedis Oficina',
  'Cedis Almacén',
  'Granjas',
  'Jardines de Morelos 2',
  'Zumpango',
  'Tecámac 4',
  'Ceda San Vicente Chicoloapan',
  'San Agustin',
  'Coacalco',
  'CD Azteca 2',
];

// ============================================================
// ====================== API (Laravel) ========================
// ============================================================
//
// CAMBIOS CLAVE:
// - Se quito "token" local (porque en la initState nunca se pasasba)
// - Ahora SIEMPRE usamos Session.token (que se guarda al hacer login)
//
// Así, cualquier request a /api/usuarios manda Authorization: Bearer TOKEN
//
class UsersApi {
  final String baseUrl; // EJ: http://127.0.0.1:8000/api

  UsersApi({required this.baseUrl});

  // Headers generales para requests
  // Si hay token, se añade Authorization
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (Session.token != null) 'Authorization': 'Bearer ${Session.token}',
  };

  // LISTAR USUARIOS con filtros:
  // - idRol: 1 admin, 2 tecnico, 3 sucursal
  // - activo: true/false/null
  // - q: search
  Future<List<dynamic>> list({int? idRol, bool? activo, String? q}) async {
    final params = <String, String>{};

    if (idRol != null) params['id_rol'] = '$idRol';
    if (activo != null) params['activo'] = activo ? '1' : '0';
    if (q != null && q.trim().isNotEmpty) params['q'] = q.trim();

    final uri = Uri.parse('$baseUrl/usuarios').replace(queryParameters: params);

    // request GET con token si existe
    final res = await http.get(uri, headers: _headers);

    // Si no es 200, lanzamos error con status + body
    if (res.statusCode != 200) {
      throw Exception('Error al listar: ${res.statusCode} ${res.body}');
    }

    return jsonDecode(res.body) as List<dynamic>;
  }

  // CREAR ADMIN
  Future<void> crearAdmin({
    required String nombre,
    required String username,
    required String password,
    required bool activo,
  }) async {
    final uri = Uri.parse('$baseUrl/usuarios/admin');
    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'nombre': nombre,
        'username': username,
        'password': password,
        'activo': activo,
      }),
    );

    // En el backend responde 201 al crear
    if (res.statusCode != 201) throw Exception(res.body);
  }

  // CREAR TECNICO
  Future<void> crearTecnico({
    required String nombre,
    required String username,
    required String password,
    required bool activo,
  }) async {
    final uri = Uri.parse('$baseUrl/usuarios/tecnico');
    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'nombre': nombre,
        'username': username,
        'password': password,
        'activo': activo,
      }),
    );

    if (res.statusCode != 201) throw Exception(res.body);
  }

  // CREAR SUCURSAL
  Future<void> crearSucursal({
    required int idSucursal,
    required String nombreSucursal,
    required String username,
    required String password,
    required bool activo,
  }) async {
    final uri = Uri.parse('$baseUrl/usuarios/sucursal');
    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'id_sucursal': idSucursal,
        'nombre_sucursal': nombreSucursal,
        'username': username,
        'password': password,
        'activo': activo,
      }),
    );

    if (res.statusCode != 201) throw Exception(res.body);
  }

  // TOGGLE (activar/desactivar)
  Future<void> toggleEstado(int idUsuario) async {
    final uri = Uri.parse('$baseUrl/usuarios/$idUsuario/estado');
    final res = await http.patch(uri, headers: _headers);

    if (res.statusCode != 200) throw Exception(res.body);
  }

  // ELIMINAR
  Future<void> eliminar(int idUsuario) async {
    final uri = Uri.parse('$baseUrl/usuarios/$idUsuario');
    final res = await http.delete(uri, headers: _headers);

    if (res.statusCode != 200) throw Exception(res.body);
  }
}

// ============================================================
// ====================== MODELO UI ===========================
// ============================================================

enum AdminUserRole { admin, tecnico, sucursal }

class AdminUserModel {
  final int id; // id real de BD (id_usuario)
  String nombre;
  String username;

  AdminUserRole rol;

  // Solo si es sucursal
  int? branchId; // id_sucursal
  String? sucursal; // nombre sucursal (si se manda)

  bool activo;

  AdminUserModel({
    required this.id,
    required this.nombre,
    required this.username,
    required this.rol,
    this.branchId,
    this.sucursal,
    required this.activo,
  });

  String get code => 'USR-${id.toString().padLeft(3, '0')}';

  static AdminUserRole roleFromId(int idRol) {
    switch (idRol) {
      case 1:
        return AdminUserRole.admin;
      case 2:
        return AdminUserRole.tecnico;
      default:
        return AdminUserRole.sucursal;
    }
  }

  factory AdminUserModel.fromJson(Map<String, dynamic> j) {
    return AdminUserModel(
      id: (j['id_usuario'] as num).toInt(), //  PK real
      nombre: (j['nombre'] ?? '').toString(),
      username: (j['username'] ?? '').toString(),
      rol: roleFromId((j['id_rol'] as num).toInt()),
      branchId: j['id_sucursal'] == null
          ? null
          : (j['id_sucursal'] as num).toInt(),
      sucursal: j['sucursal_nombre']?.toString(),
      activo: j['activo'] == true || j['activo'] == 1,
    );
  }
}

// ============================================================
// ====================== VIEW ================================
// ============================================================

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

  List<AdminUserModel> _users = [];
  bool _loading = false;

  late final UsersApi api;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);

    //  Se cambia URL dependiendo del dispositivo
    api = UsersApi(baseUrl: 'http://127.0.0.1:8000/api');

    // Carga inicial
    _loadTabUsers();

    // Cada vez que cambias tab, recarga
    _tab.addListener(() {
      if (!_tab.indexIsChanging) _loadTabUsers();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchAdminCtrl.dispose();
    _searchTechCtrl.dispose();
    _searchBranchCtrl.dispose();
    super.dispose();
  }

  // ==========================================================
  // CARGA DE USUARIOS SEGÚN TAB + FILTROS
  // ==========================================================
  Future<void> _loadTabUsers() async {
    setState(() => _loading = true);

    try {
      // debug para confirmar que sí hay token
      debugPrint('TOKEN actual: ${Session.token}');

      final idx = _tab.index;
      final idRol = idx == 0
          ? 1
          : idx == 1
          ? 2
          : 3;

      final q = idx == 0
          ? _searchAdminCtrl.text
          : idx == 1
          ? _searchTechCtrl.text
          : _searchBranchCtrl.text;

      final activo = idx == 0
          ? _activeAdmin
          : idx == 1
          ? _activeTech
          : _activeBranch;

      final data = await api.list(idRol: idRol, activo: activo, q: q);

      setState(() {
        _users = data
            .map((e) => AdminUserModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      // Muestra el error real
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar usuarios: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  // ==========================================================
  // ELIMINAR (solo inactivos)
  // ==========================================================
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
      try {
        await api.eliminar(user.id);
        await _loadTabUsers();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Usuario eliminado')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }

  // ==========================================================
  // Helpers UI
  // ==========================================================
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
    _loadTabUsers();
  }

  void _clearTechFilters() {
    setState(() {
      _searchTechCtrl.clear();
      _activeTech = null;
    });
    _loadTabUsers();
  }

  void _clearBranchFilters() {
    setState(() {
      _searchBranchCtrl.clear();
      _activeBranch = null;
    });
    _loadTabUsers();
  }

  // Los 3 métodos:
  // ===== MODAL ADMIN =====
  Future<void> _openAdminModal({AdminUserModel? user}) async {
    final isEdit = user != null;

    final nombreCtrl = TextEditingController(text: isEdit ? user!.nombre : '');
    final usernameCtrl = TextEditingController(
      text: isEdit ? user!.username : '',
    );
    final passwordCtrl = TextEditingController(
      text: '',
    ); // nunca prellenar password
    bool activo = isEdit ? user!.activo : true;

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
                          labelText: isEdit
                              ? 'Nueva contraseña (opcional)'
                              : 'Contraseña',
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
                  onPressed: () async {
                    final nombre = nombreCtrl.text.trim();
                    final username = usernameCtrl.text.trim();
                    final pass = passwordCtrl.text;

                    if (nombre.isEmpty || username.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nombre y usuario son obligatorios.'),
                        ),
                      );
                      return;
                    }

                    try {
                      if (!isEdit) {
                        if (pass.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('La contraseña es obligatoria.'),
                            ),
                          );
                          return;
                        }
                        await api.crearAdmin(
                          nombre: nombre,
                          username: username,
                          password: pass,
                          activo: activo,
                        );
                      } else {
                        // Si se quiere editar en backend, necesitas endpoint PUT /usuarios/{id}
                        // Por ahora: solo recarga (o implementamos update después).
                        // Te dejo listo el flujo para cuando tengas update.
                        // await api.updateUser(...);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Edición backend: falta endpoint PUT /usuarios/{id}',
                            ),
                          ),
                        );
                      }

                      Navigator.pop(context, true);
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  child: Text(isEdit ? 'Guardar' : 'Agregar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok == true) {
      await _loadTabUsers();
      setState(() {});
    }
  }

  // ===== MODAL TECNICO =====
  Future<void> _openTechModal({AdminUserModel? user}) async {
    final isEdit = user != null;

    final nombreCtrl = TextEditingController(text: isEdit ? user!.nombre : '');
    final usernameCtrl = TextEditingController(
      text: isEdit ? user!.username : '',
    );
    final passwordCtrl = TextEditingController(text: '');
    bool activo = isEdit ? user!.activo : true;

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
                          labelText: isEdit
                              ? 'Nueva contraseña (opcional)'
                              : 'Contraseña',
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
                  onPressed: () async {
                    final nombre = nombreCtrl.text.trim();
                    final username = usernameCtrl.text.trim();
                    final pass = passwordCtrl.text;

                    if (nombre.isEmpty || username.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nombre y usuario son obligatorios.'),
                        ),
                      );
                      return;
                    }

                    try {
                      if (!isEdit) {
                        if (pass.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('La contraseña es obligatoria.'),
                            ),
                          );
                          return;
                        }
                        await api.crearTecnico(
                          nombre: nombre,
                          username: username,
                          password: pass,
                          activo: activo,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Edición backend: falta endpoint PUT /usuarios/{id}',
                            ),
                          ),
                        );
                      }

                      Navigator.pop(context, true);
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  child: Text(isEdit ? 'Guardar' : 'Agregar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok == true) {
      await _loadTabUsers();
      setState(() {});
    }
  }

  // ===== MODAL SUCURSAL =====
  Future<void> _openBranchModal({AdminUserModel? user}) async {
    final isEdit = user != null;

    final branchIdCtrl = TextEditingController(
      text: isEdit ? (user!.branchId?.toString() ?? '') : '',
    );
    final sucursalCtrl = TextEditingController(
      text: isEdit ? (user!.nombre) : '',
    );
    final usernameCtrl = TextEditingController(
      text: isEdit ? user!.username : '',
    );
    final passwordCtrl = TextEditingController(text: '');
    bool activo = isEdit ? user!.activo : true;

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
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      Autocomplete<String>(
                        initialValue: TextEditingValue(text: sucursalCtrl.text),
                        optionsBuilder: (TextEditingValue value) {
                          final q = value.text.trim().toLowerCase();
                          if (q.isEmpty) return kSucursales;
                          return kSucursales.where(
                            (s) => s.toLowerCase().contains(q),
                          );
                        },
                        onSelected: (String selection) {
                          sucursalCtrl.text =
                              selection; // guarda la sucursal elegida
                        },
                        fieldViewBuilder:
                            (context, controller, focusNode, onFieldSubmitted) {
                              // usamos el controller del autocomplete y lo sincronizamos con sucursalCtrl
                              controller.text = sucursalCtrl.text;
                              controller.selection = TextSelection.fromPosition(
                                TextPosition(offset: controller.text.length),
                              );

                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre de sucursal',
                                  prefixIcon: Icon(Icons.store),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (v) =>
                                    sucursalCtrl.text = v, //  sync
                              );
                            },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(12),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 260,
                                  maxWidth: 520,
                                ),
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(8),
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final opt = options.elementAt(index);
                                    return ListTile(
                                      dense: true,
                                      title: Text(opt),
                                      onTap: () => onSelected(opt),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
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
                          labelText: isEdit
                              ? 'Nueva contraseña (opcional)'
                              : 'Contraseña',
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
                  onPressed: () async {
                    final bidTxt = branchIdCtrl.text.trim();
                    final suc = sucursalCtrl.text.trim();
                    final username = usernameCtrl.text.trim();
                    final pass = passwordCtrl.text;

                    if (bidTxt.isEmpty || suc.isEmpty || username.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'ID sucursal, nombre y usuario son obligatorios.',
                          ),
                        ),
                      );
                      return;
                    }

                    final bid = int.tryParse(bidTxt);
                    if (bid == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ID Sucursal debe ser número.'),
                        ),
                      );
                      return;
                    }

                    try {
                      if (!isEdit) {
                        if (pass.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('La contraseña es obligatoria.'),
                            ),
                          );
                          return;
                        }

                        await api.crearSucursal(
                          idSucursal: bid,
                          nombreSucursal: suc,
                          username: username,
                          password: pass,
                          activo: activo,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Edición backend: falta endpoint PUT /usuarios/{id}',
                            ),
                          ),
                        );
                      }

                      Navigator.pop(context, true);
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  child: Text(isEdit ? 'Guardar' : 'Agregar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok == true) {
      await _loadTabUsers();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Usuarios')),
        drawer: const AppDrawer(
          role: UserRole.admin,
          title: 'Admin',
          subtitle: 'Mesa de ayuda',
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final admins = _users.where((u) => u.rol == AdminUserRole.admin).toList();
    final technicians = _users
        .where((u) => u.rol == AdminUserRole.tecnico)
        .toList();
    final branches = _users
        .where((u) => u.rol == AdminUserRole.sucursal)
        .toList();

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
                      onActiveChanged: (v) {
                        setState(() => _activeAdmin = v);
                        _loadTabUsers();
                      },
                      onClear: _clearAdminFilters,
                      onChanged: () => _loadTabUsers(),
                      primaryLabel: 'Agregar admin',
                      primaryIcon: Icons.person_add_alt_1,
                      onPrimary: () => _openAdminModal(),
                      hint: 'Buscar (nombre, usuario, id)',
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: isWide
                          ? _UsersTable(
                              users: admins,
                              roleText: _roleText,
                              roleIcon: _roleIcon,
                              roleColor: _roleColor,
                              onEdit: (u) => _openAdminModal(user: u),
                              onToggleActive: (u) async {
                                await api.toggleEstado(u.id);
                                await _loadTabUsers();
                              },
                              onDelete: (u) => _deleteUser(u),
                            )
                          : _UsersCards(
                              users: admins,
                              roleText: _roleText,
                              roleIcon: _roleIcon,
                              roleColor: _roleColor,
                              onEdit: (u) => _openAdminModal(user: u),
                              onToggleActive: (u) async {
                                await api.toggleEstado(u.id);
                                await _loadTabUsers();
                              },
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
                      onActiveChanged: (v) {
                        setState(() => _activeTech = v);
                        _loadTabUsers();
                      },
                      onClear: _clearTechFilters,
                      onChanged: () => _loadTabUsers(),
                      primaryLabel: 'Agregar técnico',
                      primaryIcon: Icons.person_add_alt_1,
                      onPrimary: () => _openTechModal(),
                      hint: 'Buscar (nombre, usuario, id)',
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: isWide
                          ? _UsersTable(
                              users: technicians,
                              roleText: _roleText,
                              roleIcon: _roleIcon,
                              roleColor: _roleColor,
                              onEdit: (u) => _openTechModal(user: u),
                              onToggleActive: (u) async {
                                await api.toggleEstado(u.id);
                                await _loadTabUsers();
                              },
                              onDelete: (u) => _deleteUser(u),
                            )
                          : _UsersCards(
                              users: technicians,
                              roleText: _roleText,
                              roleIcon: _roleIcon,
                              roleColor: _roleColor,
                              onEdit: (u) => _openTechModal(user: u),
                              onToggleActive: (u) async {
                                await api.toggleEstado(u.id);
                                await _loadTabUsers();
                              },
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
                      onActiveChanged: (v) {
                        setState(() => _activeBranch = v);
                        _loadTabUsers();
                      },
                      onClear: _clearBranchFilters,
                      onChanged: () => _loadTabUsers(),
                      primaryLabel: 'Agregar sucursal',
                      primaryIcon: Icons.add_business,
                      onPrimary: () => _openBranchModal(),
                      hint: 'Buscar (id sucursal, nombre, usuario, id)',
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: isWide
                          ? _UsersTable(
                              users: branches,
                              roleText: _roleText,
                              roleIcon: _roleIcon,
                              roleColor: _roleColor,
                              onEdit: (u) => _openBranchModal(user: u),
                              onToggleActive: (u) async {
                                await api.toggleEstado(u.id);
                                await _loadTabUsers();
                              },
                              onDelete: (u) => _deleteUser(u),
                            )
                          : _UsersCards(
                              users: branches,
                              roleText: _roleText,
                              roleIcon: _roleIcon,
                              roleColor: _roleColor,
                              onEdit: (u) => _openBranchModal(user: u),
                              onToggleActive: (u) async {
                                await api.toggleEstado(u.id);
                                await _loadTabUsers();
                              },
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

// ============================================================
// =================== COMPONENTES  ===========================
// ============================================================

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

// ===================== MOBILE: CARDS =====================

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
            ? '\n${u.branchId?.toString() ?? ""} • ${u.nombre}'
            : '';

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: c.withOpacity(0.15),
              child: Icon(roleIcon(u.rol), color: c),
            ),
            title: Text(
              '${u.nombre} • ${u.code}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              'Usuario: ${u.username}\n'
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

// ===================== WEB/DESKTOP: TABLE =====================

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
                          ? '${u.branchId?.toString() ?? ""} • ${u.nombre}'
                          : '—';

                      return DataRow(
                        cells: [
                          DataCell(Text(u.code)),
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
