import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/app_drawer.dart';
import '../../services/session.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;

class TechnicianTasksView extends StatefulWidget {
  const TechnicianTasksView({super.key});

  @override
  State<TechnicianTasksView> createState() => _TechnicianTasksViewState();
}

class _TechnicianTasksViewState extends State<TechnicianTasksView> {
  List tareas = [];
  bool loading = true;

  final String baseUrl = "http://localhost:8000/api";

  @override
  void initState() {
    super.initState();
    fetchTareas();
  }

  Future<void> fetchTareas() async {
    final res = await http.get(
      Uri.parse("$baseUrl/mis-tareas"),
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

  /// =========================
  /// FINALIZAR
  /// =========================
  Future<void> finalizarTarea(int id, String solucion) async {
    final res = await http.post(
      Uri.parse("$baseUrl/tareas/$id/finalizar"),
      headers: {
        "Authorization": "Bearer ${Session.token}",
        "Accept": "application/json",
      },
      body: {"solucion": solucion},
    );

    print("STATUS: ${res.statusCode}");
    print("BODY: ${res.body}");

    if (res.statusCode == 200) {
      fetchTareas();
      Navigator.pop(context);
    } else {
      // 🔥 MOSTRAR ERROR REAL
      showDialog(
        context: context,
        builder: (_) =>
            AlertDialog(title: const Text("Error"), content: Text(res.body)),
      );
    }
  }

  Future<void> descargarPDF(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer ${Session.token}",
          "Accept": "application/pdf",
        },
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        if (kIsWeb) {
          // WEB
          final blob = html.Blob([bytes]);
          final downloadUrl = html.Url.createObjectUrlFromBlob(blob);

          html.AnchorElement(href: downloadUrl)
            ..setAttribute("download", "memoria_tarea.pdf")
            ..click();

          html.Url.revokeObjectUrl(downloadUrl);
        } else {
          // MOBILE / DESKTOP
          final dir = await getApplicationDocumentsDirectory();
          final file = File('${dir.path}/memoria_tarea.pdf');

          await file.writeAsBytes(bytes);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("PDF guardado en: ${file.path}")),
          );
        }
      } else {
        print(response.body);
      }
    } catch (e) {
      print(e);
    }
  }

  void descargarWeb(String url) {
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "memoria_tarea.pdf")
      ..click();
  }

  /// =========================
  /// MODAL
  /// =========================
  ///
  void showFinalizarModal(int id) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Finalizar tarea"),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: "Describe la solución...",
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Finalizar"),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                finalizarTarea(id, controller.text);
              }
            },
          ),
        ],
      ),
    );
  }

  void showDetalle(t) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            // 👈 por si crece
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t["titulo"],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                _item("📍 Sucursal", t["sucursal"]),
                _item("⚙️ Problema", t["problematica"]),
                _item("📝 Descripción", t["descripcion"]),
                _item("🧰 Materiales", t["materiales"] ?? "No especificado"),
                _item("📅 Fecha límite", t["fecha_limite"]),

                const SizedBox(height: 12),

                Row(
                  children: [
                    _chipEstado(t["estado"]),
                    const SizedBox(width: 8),
                    _chipPrioridad(t["prioridad"]),
                  ],
                ),

                const SizedBox(height: 16),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    child: const Text("Cerrar"),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87),
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: value ?? "-",
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  /// =========================
  /// ABRIR PDF
  /// =========================
  Future<void> abrirPDF(String url) async {
    final uri = Uri.parse(url);

    if (!await launchUrl(uri)) {
      throw Exception("No se pudo abrir el PDF");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text("Mis tareas"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      drawer: const AppDrawer(role: UserRole.tecnico, title: 'Técnico'),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tareas.length,
                  itemBuilder: (context, i) {
                    final t = tareas[i];
                    return _taskCard(t);
                  },
                ),
              ),
            ),
    );
  }

  /// =========================
  /// CARD PRO
  /// =========================
  Widget _taskCard(t) {
    final isDone = t["estado"] == "finalizado";

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
          /// TITULO
          Text(
            t["titulo"],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),

          /// PROBLEMATICA
          Text(
            t["problematica"],
            style: const TextStyle(color: Colors.black54),
          ),

          const SizedBox(height: 10),

          /// SUCURSAL
          Row(
            children: [
              const Icon(Icons.store, size: 16),
              const SizedBox(width: 6),
              Text(t["sucursal"]),
            ],
          ),

          const SizedBox(height: 10),

          /// CHIPS
          Row(
            children: [
              _chipEstado(t["estado"]),
              const SizedBox(width: 8),
              _chipPrioridad(t["prioridad"]),
            ],
          ),

          const SizedBox(height: 14),

          /// ACCIONES
          Row(
            children: [
              if (!isDone)
                ElevatedButton(
                  onPressed: () => showFinalizarModal(t["id_tarea"]),
                  child: const Text("Finalizar"),
                ),

              const SizedBox(width: 8),

              /// 👁️ VER DETALLE
              OutlinedButton.icon(
                icon: const Icon(Icons.visibility),
                label: const Text("Detalle"),
                onPressed: () => showDetalle(t),
              ),

              const SizedBox(width: 8),

              if (isDone && t["pdf_url"] != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text("Descargar"),
                  onPressed: () {
                    final url = "$baseUrl/tareas/${t["id_tarea"]}/memoria";

                    if (kIsWeb) {
                       descargarWeb(url);
                    } else {
                      descargarPDF(url);
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// =========================
  /// CHIPS
  /// =========================
  Widget _chipEstado(String estado) {
    Color color = estado == "pendiente" ? Colors.orange : Colors.green;

    return Chip(
      label: Text(estado),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color),
    );
  }

  Widget _chipPrioridad(int p) {
    Color color;
    String texto;

    switch (p) {
      case 1:
        color = Colors.red;
        texto = "🔴 Alta";
        break;
      case 2:
        color = Colors.orange;
        texto = "🟠 Media";
        break;
      default:
        color = Colors.green;
        texto = "🟢 Baja";
    }

    return Chip(
      label: Text(texto),
      backgroundColor: color.withOpacity(0.15),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
