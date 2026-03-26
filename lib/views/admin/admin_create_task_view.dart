import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';

class AdminCreateTaskView extends StatefulWidget {
  const AdminCreateTaskView({super.key});

  @override
  State<AdminCreateTaskView> createState() => _AdminCreateTaskViewState();
}

class _AdminCreateTaskViewState extends State<AdminCreateTaskView> {
  final tituloController = TextEditingController();
  final descripcionController = TextEditingController();
  final materialesController = TextEditingController();

  DateTime? fechaLimite;
  int? prioridad;

  final Color primaryColor = const Color(0xFF4CAF50);
  final Color bgColor = const Color(0xFFF5F7FA);

  /// ============================
  /// BACKEND READY 🚀
  /// ============================
  Future<void> _submitTask() async {
    if (tituloController.text.isEmpty ||
        descripcionController.text.isEmpty ||
        prioridad == null ||
        fechaLimite == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos")),
      );
      return;
    }

    final body = {
      "titulo": tituloController.text,
      "descripcion": descripcionController.text,
      "materiales": materialesController.text,
      "fecha_limite": fechaLimite.toString(),
      "prioridad": prioridad,
    };

    print("ENVIANDO A BACKEND:");
    print(body);

    // 🔥 Aquí luego metes tu API
    // await TasksApi.create(body);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Tarea creada")));
  }

  Color _getPriorityColor(int p) {
    switch (p) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Crear tarea'),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      drawer: const AppDrawer(role: UserRole.admin, title: 'Administrador'),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            width: 800,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),

            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// HEADER SIMPLE (como métricas)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.task_alt, color: primaryColor),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Nueva tarea",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  /// INPUTS MÁS LIMPIOS
                  _input(controller:tituloController,label: "Título" ),

                  const SizedBox(height: 15),

                  _input(
                    controller: descripcionController,
                    label: "Descripción",
                  ),
                  _input(controller: materialesController, label: "Materiales"),

                  /// FECHA + PRIORIDAD
                  Row(
                    children: [
                      /// FECHA
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );

                            if (picked != null) {
                              setState(() => fechaLimite = picked);
                            }
                          },
                          child: Container(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              fechaLimite == null
                                  ? "Seleccionar fecha"
                                  : fechaLimite.toString().split(' ')[0],
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      /// PRIORIDAD (estilo tuyo)
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: prioridad,
                          decoration: InputDecoration(
                            labelText: "Prioridad",
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: [1, 2, 3].map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _getPriorityColor(p),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text("Prioridad $p"),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => prioridad = v),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  /// BOTÓN MÁS DISCRETO (como tu sistema)
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _submitTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text("Crear tarea"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// INPUT BONITO
  Widget _input({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
