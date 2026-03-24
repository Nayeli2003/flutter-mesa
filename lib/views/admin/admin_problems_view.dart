import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';

class AdminProblemsView extends StatefulWidget {
  const AdminProblemsView({super.key});

  @override
  State<AdminProblemsView> createState() => _AdminProblemsViewState();
}

class _AdminProblemsViewState extends State<AdminProblemsView> {

  List problemas = [];

  @override
  void initState() {
    super.initState();
    cargarProblemas();
  }

  void cargarProblemas() {
  setState(() {
    problemas = [
      {
        'id_tipo_problema': 1,
        'nombre': 'Error al facturar al cliente',
        'prioridad': 'alta',
        'activo': true,
      },
      {
        'id_tipo_problema': 2,
        'nombre': 'Falla de conexión',
        'prioridad': 'media',
        'activo': true,
      },
      {
        'id_tipo_problema': 3,
        'nombre': 'Producto Talla/Color',
        'prioridad': 'baja',
        'activo': true,
      },
      {
        'id_tipo_problema': 4,
        'nombre': 'Falla en el correo',
        'prioridad': 'media',
        'activo': true,
      },
      {
        'id_tipo_problema': 5,
        'nombre': 'Error en serie de factura',
        'prioridad': 'alta',
        'activo': true,
      },
    ];
  });
}

  void crear() {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Crear problema')),
  );
}

  void editar(dynamic item) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Editar ${item['nombre']}')),
  );
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
    setState(() {
      item['activo'] = !item['activo'];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Problema ${accion}do')),
    );
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Problema eliminado')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(
        role: UserRole.admin,
        title: 'Admin',
      ),

      appBar: AppBar(
        title: const Text('Problemas'),
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// 🔎 BUSCADOR
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
                      )
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

                      return _ProblemCard(
  nombre: item['nombre'],
  prioridad: item['prioridad'],
  activo: item['activo'],
  onEdit: () => editar(item),
  onToggle: () => toggleEstado(item['id_tipo_problema']),
  onDelete: () => eliminar(item['id_tipo_problema']),
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

class _ProblemCard extends StatelessWidget {
  final String nombre;
  final String prioridad;
  final bool activo;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ProblemCard({
    required this.nombre,
    required this.prioridad,
    required this.activo,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  Color _colorPrioridad() {
    switch (prioridad.toLowerCase()) {
      case 'alta':
        return Colors.red.shade300;
      case 'media':
        return Colors.orange.shade300;
      default:
        return Colors.green.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children: [

          Expanded(
            flex: 3,
            child: Text(nombre),
          ),

          Expanded(
            flex: 2,
            child: Chip(
              label: Text(prioridad),
              backgroundColor: _colorPrioridad(),
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              activo ? 'Activo' : 'Inactivo',
              style: TextStyle(
                color: activo ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            flex: 3,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: Icon(
                    activo ? Icons.block : Icons.check_circle,
                    color: activo ? Colors.orange : Colors.green,
                  ),
                  onPressed: onToggle,
                ),
                if (!activo)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onDelete,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}