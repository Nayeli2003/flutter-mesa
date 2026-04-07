import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/session.dart';
import '../../config/api_config.dart';

class AdminProblemsView extends StatefulWidget {
  const AdminProblemsView({super.key});

  @override
  State<AdminProblemsView> createState() => _AdminProblemsViewState();
}

class _AdminProblemsViewState extends State<AdminProblemsView> {
  List problemas = [];

  int? editingId;

  @override
  void initState() {
    super.initState();
    cargarProblemas();
  }

  Future<void> crearProblema(
    String nombre,
    String descripcion,
    String prioridad,
  ) async {
    try {
      // convertir texto → id
      int idPrioridad = prioridad == 'alta'
          ? 3
          : prioridad == 'media'
          ? 2
          : 1;

      final response = await http.post(
        Uri.parse(ApiConfig.tipoProblema),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${Session.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nombre': nombre,
          'descripcion': descripcion,
          'id_prioridad': idPrioridad,
        }),
      );

      if (response.statusCode == 201) {
        print('✅ Creado');
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error: ${response.body}')));
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> cargarProblemas() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.tipoProblema),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${Session.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          problemas = data;
        });
      } else {
        print('Error al cargar problemas');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void crear() {
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();
    String prioridad = 'baja';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Crear problema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: descripcionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: prioridad,
              items: [
                'alta',
                'media',
                'baja',
              ].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (value) {
                prioridad = value!;
              },
              decoration: const InputDecoration(labelText: 'Prioridad'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nombreController.text.isEmpty ||
                  descripcionController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Todos los campos son obligatorios'),
                  ),
                );
                return;
              }

              // 🔥 LOADING
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );

              await crearProblema(
                nombreController.text,
                descripcionController.text,
                prioridad,
              );

              Navigator.pop(context); // cerrar loading
              Navigator.pop(context); // cerrar modal

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Problema creado correctamente'),
                ),
              );

              await cargarProblemas();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> eliminarBackend(int id) async {
    await http.delete(
      Uri.parse(ApiConfig.tipoProblemaById(id)),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${Session.token}',
      },
    );
  }

  void editar(dynamic item) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Editar ${item['nombre']}')));
  }

  void toggleEstado(int id) async {
    final item = problemas.firstWhere((e) => e['id_tipo_problema'] == id);

    final accion = item['activo'] ? 'desactivar' : 'activar';

    final confirmar = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${accion.toUpperCase()} problema'),
        content: Text('¿Seguro que quieres $accion este problema?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      // 👇 AQUÍ ES DONDE CAMBIA TODO
      await toggleBackend(id); // 🔥 guarda en BD

      setState(() {
        item['activo'] = !item['activo']; // 🔥 actualiza UI
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Problema ${accion}do')));
    }
  }

  void eliminar(int id) async {
    final confirmar = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar problema'),
        content: const Text('¿Seguro que quieres eliminar este problema?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() {
        problemas.removeWhere((e) => e['id_tipo_problema'] == id);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Problema eliminado')));
    }
  }

  Future<void> actualizarPrioridad(int id, String prioridad) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.tipoProblemaById(id)),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${Session.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'prioridad': prioridad}),
      );

      if (response.statusCode == 200) {
        print('✅ Prioridad actualizada');
      } else {
        print('❌ Error al actualizar');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> toggleBackend(int id) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.toggleProblema(id)),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${Session.token}',
        },
      );

      if (response.statusCode == 200) {
        print('✅ Estado actualizado en BD');
      } else {
        print('❌ Error toggle: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(role: UserRole.admin, title: 'Admin'),

      appBar: AppBar(title: const Text('Problemas')),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// BUSCADOR
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Buscar problema...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// 📋 LISTA DINÁMICA
                Expanded(
                  child: ListView.builder(
                    itemCount: problemas.length,
                    itemBuilder: (context, index) {
                      final item = problemas[index];

                      return ProblemCard(
                        item: item,
                        isEditing: editingId == item['id_tipo_problema'],
                        onEdit: () {
                          setState(() {
                            editingId = item['id_tipo_problema'];
                          });
                        },
                        onToggle: () => toggleEstado(item['id_tipo_problema']),
                        onDelete: () async {
                          try {
                            await eliminarBackend(item['id_tipo_problema']);
                            eliminar(item['id_tipo_problema']);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('❌ Error al eliminar'),
                              ),
                            );
                          }
                        },
                        onChangePrioridad: (value) async {
                          setState(() {
                            item['prioridad'] = value;
                            editingId = null; // se bloquea otra vez
                          });

                          await actualizarPrioridad(
                            item['id_tipo_problema'],
                            value,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => crear(),
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ProblemCard extends StatelessWidget {
  final Map item;
  final bool isEditing;
  final Function onEdit;
  final Function onToggle;
  final Function onDelete;
  final Function(String) onChangePrioridad;

  const ProblemCard({
    super.key,
    required this.item,
    required this.isEditing,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
    required this.onChangePrioridad,
  });

  Color _getColor(String prioridad) {
    switch (prioridad.toLowerCase()) {
      case 'alta':
        return Colors.red;
      case 'media':
        return Colors.orange;
      case 'baja':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prioridad = item['prioridad'] ?? 'baja';
    final color = _getColor(prioridad);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black12)],
      ),
      child: Row(
        children: [
          /// 🟢 NOMBRE
          Expanded(
            flex: 2,
            child: Text(
              item['nombre'],
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),

          /// 🟡 DESCRIPCIÓN
          Expanded(
            flex: 3,
            child: Text(
              item['descripcion'] ?? '',
              style: const TextStyle(color: Colors.black54),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          /// 🔴 PRIORIDAD (DROPDOWN)
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value:
                    ['alta', 'media', 'baja'].contains(prioridad?.toLowerCase())
                    ? prioridad!.toLowerCase()
                    : null,
                isExpanded: true,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down),

                items: ['alta', 'media', 'baja']
                    .map(
                      (p) => DropdownMenuItem<String>(
                        value: p,
                        child: Text(p, style: TextStyle(color: color)),
                      ),
                    )
                    .toList(),

                onChanged: isEditing
                    ? (value) => onChangePrioridad(value!)
                    : null,
              ),
            ),
          ),

          const SizedBox(width: 30), // separación
          /// 🟢 ESTADO
          Expanded(
            flex: 1,
            child: Text(
              item['activo'] ? 'Activo' : 'Inactivo',
              style: TextStyle(
                color: item['activo'] ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          /// ⚙️ ACCIONES
          Row(
            children: [
              /// ✏️ EDITAR
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.black54),
                onPressed: () => onEdit(),
              ),

              /// 🟢 SI ESTÁ ACTIVO → DESACTIVAR
              if (item['activo'])
                IconButton(
                  icon: const Icon(Icons.block, color: Colors.orange),
                  onPressed: () => onToggle(),
                ),

              /// 🔴 SI ESTÁ INACTIVO → ACTIVAR + ELIMINAR
              if (!item['activo']) ...[
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () => onToggle(), // activar
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => onDelete(),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
