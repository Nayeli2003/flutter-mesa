import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/session.dart';
import 'dart:html' as html;

class AdminTasksView extends StatefulWidget {
  const AdminTasksView({super.key});

  @override
  State<AdminTasksView> createState() => _AdminTasksViewState();
}

class _AdminTasksViewState extends State<AdminTasksView> {
  int get total => tareas.length;

  int get proceso => tareas.where((t) => t["estado"] == "pendiente").length;

  int get cerrados => tareas.where((t) => t["estado"] == "finalizado").length;
  List tareas = [];
  List tecnicos = [];
  bool loading = true;

  final String baseUrl = "http://localhost:8000/api";

  @override
  void initState() {
    super.initState();
    fetchTareas();
    fetchTecnicos();
  }

  Future<void> fetchTareas() async {
    final res = await http.get(
      Uri.parse("$baseUrl/tareas"),
      headers: {
        "Authorization": "Bearer ${Session.token}",
        "Accept": "application/json",
      },
    );

    if (res.statusCode == 200) {
      setState(() {
        tareas = json.decode(res.body);
        loading = false;
      });
    }
  }

  Future<void> reabrirTarea(int id) async {
    final res = await http.post(
      Uri.parse("$baseUrl/tareas/$id/reabrir"),
      headers: {
        "Authorization": "Bearer ${Session.token}",
        "Accept": "application/json",
      },
    );

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Tarea reabierta")));

      fetchTareas();
    } else {
      print(res.body);
    }
  }

  Future<void> fetchTecnicos() async {
    final res = await http.get(
      Uri.parse("$baseUrl/tecnicos"),
      headers: {
        "Authorization": "Bearer ${Session.token}",
        "Accept": "application/json",
      },
    );

    if (res.statusCode == 200) {
      tecnicos = json.decode(res.body);
    }
  }

  Future<void> finalizarTarea(int id) async {
    final solucionController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Finalizar tarea"),
        content: TextField(
          controller: solucionController,
          decoration: const InputDecoration(labelText: "Solución"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              final res = await http.post(
                Uri.parse("$baseUrl/tareas/$id/finalizar"),
                headers: {
                  "Authorization": "Bearer ${Session.token}",
                  "Accept": "application/json",
                  "Content-Type": "application/json",
                },
                body: jsonEncode({"solucion": solucionController.text}),
              );

              Navigator.pop(context);

              if (res.statusCode == 200) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Tarea finalizada")),
                );
                fetchTareas();
              } else {
                print(res.body);
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  void descargarPDF(int id) {
    final url = "$baseUrl/tareas/$id/memoria";

    // web
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "memoria_tarea.pdf")
      ..click();
  }

  void editarTarea(BuildContext context, t) {
    final titulo = TextEditingController(text: t["titulo"]);
    final descripcion = TextEditingController(text: t["descripcion"]);
    final materiales = TextEditingController(text: t["materiales"]);

    List<int> seleccionados = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Editar tarea"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: titulo,
                      decoration: const InputDecoration(labelText: "Título"),
                    ),
                    TextField(
                      controller: descripcion,
                      decoration: const InputDecoration(
                        labelText: "Descripción",
                      ),
                    ),
                    TextField(
                      controller: materiales,
                      decoration: const InputDecoration(
                        labelText: "Materiales",
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text("Técnicos"),

                    ...tecnicos.map((tec) {
                      final selected = seleccionados.contains(
                        tec["id_usuario"],
                      );

                      return CheckboxListTile(
                        title: Text(tec["nombre"]),
                        value: selected,
                        onChanged: (val) {
                          if (val == true) {
                            seleccionados.add(tec["id_usuario"]);
                          } else {
                            seleccionados.remove(tec["id_usuario"]);
                          }

                          setStateDialog(() {});
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await http.put(
                      Uri.parse("$baseUrl/tareas/${t["id_tarea"]}"),
                      headers: {
                        "Authorization": "Bearer ${Session.token}",
                        "Content-Type": "application/json",
                      },
                      body: jsonEncode({
                        "titulo": titulo.text,
                        "descripcion": descripcion.text,
                        "problematica": t["problematica"],
                        "materiales": materiales.text,
                        "fecha_limite": t["fecha_limite"],
                        "prioridad": t["prioridad"],
                        "tecnicos": seleccionados,
                      }),
                    );

                    Navigator.pop(context);
                    fetchTareas();
                  },
                  child: const Text("Guardar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  //aqui
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text("Administrador"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      drawer: const AppDrawer(role: UserRole.admin, title: 'Administrador'),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                /// MÉTRICAS BONITAS
                Row(
                  children: [
                    _metricCard(
                      "Total",
                      total,
                      Colors.blue,
                      Icons.confirmation_number,
                    ),
                    const SizedBox(width: 10),
                    _metricCard(
                      "Proceso",
                      proceso,
                      Colors.orange,
                      Icons.timelapse,
                    ),
                    const SizedBox(width: 10),
                    _metricCard(
                      "Cerrados",
                      cerrados,
                      Colors.green,
                      Icons.check_circle,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                /// LISTA
                Expanded(
                  child: ListView.builder(
                    itemCount: tareas.length,
                    itemBuilder: (context, index) =>
                        _adminCard(context, tareas[index]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// =========================
  /// MÉTRICAS
  /// =========================
  Widget _metricCard(String title, int value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 6),
            Text(
              "$value",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  /// =========================
  /// CARD DE TICKET
  /// =========================
  Widget _adminCard(BuildContext context, t) {
    final isDone = t["estado"] == "finalizado";
    final sinTecnico = t["tecnico"] == null || t["tecnico"] == "";
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TÍTULO
          Text(
            t["titulo"],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              const Icon(Icons.store, size: 16, color: Colors.black45),
              const SizedBox(width: 6),
              Text(
                t["sucursal"],
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Colors.black45),
              const SizedBox(width: 6),
              Text(
                sinTecnico ? "Sin asignar" : t["tecnico"],
                style: TextStyle(
                  color: sinTecnico ? Colors.redAccent : Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// ACCIONES
          Row(
            children: [
              _statusChip(t["estado"]),
              const Spacer(),

              if (isDone)
                _iconAction(Icons.refresh, Colors.orange, () {
                  reabrirTarea(t["id_tarea"]);
                }),

              if (!isDone)
                _iconAction(Icons.check, Colors.green, () {
                  finalizarTarea(t["id_tarea"]);
                }),

              if (isDone)
                _iconAction(Icons.picture_as_pdf, Colors.red, () {
                  descargarPDF(t["id_tarea"]);
                }),

              const SizedBox(width: 8),
              _iconAction(Icons.visibility, Colors.grey, () {}),
              _iconAction(Icons.edit, Colors.blue, () {
                editarTarea(context, t);
              }),
            ],
          ),
        ],
      ),
    );
  }

  /// =========================
  /// BOTÓN ICONO BONITO
  /// =========================
  Widget _iconAction(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  /// =========================
  /// STATUS CHIP
  /// =========================
  Widget _statusChip(String status) {
    Color color;

    switch (status) {
      case "pendiente":
        color = Colors.orange;
        break;
      case "finalizado":
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
