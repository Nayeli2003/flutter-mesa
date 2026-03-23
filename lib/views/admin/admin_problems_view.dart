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
    // TEMPORAL (luego lo conectamos a Laravel)
    setState(() {
      problemas = [
        {'id_tipo_problema': 1, 'nombre': 'Error al facturar al cliente'},
        {'id_tipo_problema': 2, 'nombre': 'Falla de conexión'},
        {'id_tipo_problema': 3, 'nombre': 'Producto Talla/Color'},
        {'id_tipo_problema': 4, 'nombre': 'Falla en el correo'},
        {'id_tipo_problema': 5, 'nombre': 'Error en serie de factura'},
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

  void eliminar(int id) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Eliminar ID $id')),
  );
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
                        onEdit: () => editar(item),
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProblemCard({
    required this.nombre,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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

          /// ICONO
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: Color(0xFF4CAF50)),
          ),

          const SizedBox(width: 14),

          /// TEXTO
          Expanded(
            child: Text(
              nombre,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),

          /// ACCIONES (YA FUNCIONAN)
          Row(
            children: [
              GestureDetector(
                onTap: onEdit,
                child: const Icon(Icons.edit, size: 20, color: Colors.grey),
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.delete, size: 20, color: Colors.red),
              ),
            ],
          )
        ],
      ),
    );
  }
}