import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/session.dart';

class AdminCreateTaskView extends StatefulWidget {
  const AdminCreateTaskView({super.key});

  @override
  State<AdminCreateTaskView> createState() => _AdminCreateTaskViewState();
}

class _AdminCreateTaskViewState extends State<AdminCreateTaskView> {
  final tituloController = TextEditingController();
  final descripcionController = TextEditingController();
  final materialesController = TextEditingController();
  final tipoProblemaController = TextEditingController();
  List<Map<String, dynamic>> technicians = [];

  final List<int> selectedTechnicians = [];

  DateTime? fechaLimite;
  int? prioridad;

  final Color primaryColor = const Color(0xFF4CAF50);
  final Color bgColor = const Color(0xFFF5F7FA);

  List<Map<String, dynamic>> sucursales = [];
  int? sucursalSeleccionada;

  /// ============================
  /// BACKEND READY
  /// ============================
  ///
  ///
  Future<void> _loadSucursales() async {
    final url = Uri.parse("http://127.0.0.1:8000/api/sucursales");

    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer ${Session.token}"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        sucursales = List<Map<String, dynamic>>.from(data);
      });
    } else {
      print("Error cargando sucursales");
    }
  }

  Future<void> _loadTechnicians() async {
    final url = Uri.parse("http://127.0.0.1:8000/api/tecnicos");

    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer ${Session.token}"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        technicians = List<Map<String, dynamic>>.from(data);
      });
    } else {
      print("Error cargando técnicos");
    }
  }

  Future<void> _submitTask() async {
    if (tituloController.text.isEmpty ||
        descripcionController.text.isEmpty ||
        fechaLimite == null ||
        selectedTechnicians.isEmpty ||
        prioridad == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos")),
      );
      return;
    }

    // 🔥 VALIDAR PROBLEMÁTICA (TE FALTABA)
    if (tipoProblemaController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Escribe la problemática")));
      return;
    }

    if (sucursalSeleccionada == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Selecciona sucursal")));
      return;
    }

    final url = Uri.parse("http://127.0.0.1:8000/api/tareas");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${Session.token}",
      },
      body: jsonEncode({
        "titulo": tituloController.text.trim(),
        "descripcion": descripcionController.text.trim(),
        "problematica": tipoProblemaController.text.trim(),
        "materiales": materialesController.text.trim(),
        "fecha_limite": fechaLimite!.toIso8601String(),
        "prioridad": prioridad,
        "id_sucursal": sucursalSeleccionada,
        "tecnicos": selectedTechnicians,
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Tarea creada")));

      // LIMPIAR FORM 
      tituloController.clear();
      descripcionController.clear();
      materialesController.clear();
      tipoProblemaController.clear();

      setState(() {
        selectedTechnicians.clear();
        prioridad = null;
        fechaLimite = null;
        sucursalSeleccionada = null;
      });
    } else {
      print(response.body);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error al crear tarea")));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTechnicians();
    _loadSucursales();
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
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Crear tarea'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      drawer: const AppDrawer(role: UserRole.admin, title: 'Administrador'),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 560,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _inputClean("Asunto", tituloController),

                const SizedBox(height: 14),

                _inputClean("Descripción", descripcionController, maxLines: 4),

                const SizedBox(height: 14),

                _inputClean("Problemática", tipoProblemaController),

                const SizedBox(height: 14),

                _inputClean("Materiales", materialesController, maxLines: 2),

                const SizedBox(height: 14),

                _dateField(),

                const SizedBox(height: 14),

                _techniciansSelector(),

                const SizedBox(height: 14),
                _prioritySelector(),

                const SizedBox(height: 14),
                _sucursalSelector(),

                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF4EA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "El administrador puede asignar uno o varios técnicos y definir la fecha límite de atención.",
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitTask,
                    icon: const Icon(Icons.send),
                    label: const Text("Guardar tarea"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sucursalSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<int>(
        value: sucursalSeleccionada,
        isExpanded: true,
        underline: const SizedBox(),
        hint: const Text("Selecciona sucursal"),
        items: sucursales.map((s) {
          return DropdownMenuItem<int>(
            value: s["id_sucursal"],
            child: Text(s["nombre"]),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            sucursalSeleccionada = value;
          });
        },
      ),
    );
  }

  Widget _prioritySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<int>(
        value: prioridad,
        isExpanded: true,
        underline: const SizedBox(),
        hint: const Text("Selecciona prioridad"),
        items: const [
          DropdownMenuItem(value: 1, child: Text("Baja")),
          DropdownMenuItem(value: 2, child: Text("Media")),
          DropdownMenuItem(value: 3, child: Text("Alta")),
        ],
        onChanged: (value) {
          setState(() => prioridad = value);
        },
      ),
    );
  }

  Widget _dateField() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: fechaLimite ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
        );

        if (picked != null) {
          setState(() => fechaLimite = picked);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: Colors.black54,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              fechaLimite == null
                  ? "Fecha límite"
                  : "${fechaLimite!.day.toString().padLeft(2, '0')}/"
                        "${fechaLimite!.month.toString().padLeft(2, '0')}/"
                        "${fechaLimite!.year}",
              style: TextStyle(
                fontSize: 15,
                color: fechaLimite == null ? Colors.black54 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _techniciansSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Asignar técnicos",
            style: TextStyle(
              fontSize: 15,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: technicians.map((tech) {
              final selected = selectedTechnicians.contains(tech["id_usuario"]);

              return FilterChip(
                label: Text(tech["nombre"]),
                selected: selected,
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      selectedTechnicians.add(tech["id_usuario"]);
                    } else {
                      selectedTechnicians.remove(tech["id_usuario"]);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _inputClean(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: label,
        filled: true,
        fillColor: const Color(0xFFF1F3F5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 1.2),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      hintText: label,
      filled: true,
      fillColor: const Color(0xFFF1F3F5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
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
