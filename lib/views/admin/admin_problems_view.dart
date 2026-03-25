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
        'descripcion': 'No permite generar factura correctamente',
        'prioridad': 'alta',
        'activo': true,
      },
      {
        'id_tipo_problema': 2,
        'nombre': 'Falla de conexión',
        'descripcion': 'No hay acceso a internet',
        'prioridad': 'media',
        'activo': true,
      },
      {
        'id_tipo_problema': 3,
        'nombre': 'Producto Talla/Color',
        'descripcion': 'No hay acceso a internet',
        'prioridad': 'baja',
        'activo': true,
      },
      {
        'id_tipo_problema': 4,
        'nombre': 'Falla en el correo',
        'descripcion': 'No hay acceso a internet',
        'prioridad': 'media',
        'activo': true,
      },
      {
        'id_tipo_problema': 5,
        'nombre': 'Error en serie de factura',
        'descripcion': 'No hay acceso a internet',
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

                      return ProblemCard(
  item: item,
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

class ProblemCard extends StatelessWidget {
  final Map item;
  final Function onEdit;
  final Function onToggle;
  final Function onDelete;

  const ProblemCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
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
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            color: Colors.black12,
          )
        ],
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
                value: prioridad,
                isExpanded: true,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down),
                items: ['alta', 'media', 'baja']
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(
                            p,
                            style: TextStyle(color: color),
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  // aquí llamas update prioridad
                },
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
)
        ],
      ),
    );
  }
}