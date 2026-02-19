import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'session.dart';

class TicketsApi {
  final String baseUrl;

  TicketsApi({required this.baseUrl});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (Session.token != null)
          'Authorization': 'Bearer ${Session.token}',
      };

  // LISTAR TICKETS ADMIN/TECNICO
  Future<List<dynamic>> list() async {
    final uri = Uri.parse('$baseUrl/tickets');

    final res = await http.get(uri, headers: _headers);

    if (res.statusCode != 200) {
      throw Exception(res.body);
    }

    return jsonDecode(res.body);
  }

  // MIS TICKETS TECNICO
  Future<List<dynamic>> misTickets() async {
    final uri = Uri.parse('$baseUrl/mis-tickets');

    final res = await http.get(uri, headers: _headers);

    if (res.statusCode != 200) {
      throw Exception(res.body);
    }

    return jsonDecode(res.body);
  }

  // CREAR TICKET
  Future<void> crear({
    required String titulo,
    required String descripcion,
    required int idPrioridad,
    required int idTipoProblema,
  }) async {
    final uri = Uri.parse('$baseUrl/tickets');

    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        "titulo": titulo,
        "descripcion": descripcion,
        "id_prioridad": idPrioridad,
        "id_tipo_problema": idTipoProblema,
      }),
    );

    if (res.statusCode != 201) {
      throw Exception(res.body);
    }
  }

  // RESOLVER TICKET TECNICO
  Future<void> resolver({
    required int idTicket,
    required int idEstado,
    required String solucion,
    required String observaciones,
  }) async {
    final uri =
        Uri.parse('$baseUrl/tickets/$idTicket/resolver');

    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        "id_estado": idEstado,
        "solucion": solucion,
        "observaciones": observaciones,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception(res.body);
    }
  }

  // DESCARGAR PDF ADMIN/TECNICO
  Future<File> descargarPdf(int idTicket) async {
    final uri =
        Uri.parse('$baseUrl/tickets/$idTicket/pdf');

    final res = await http.get(
      uri,
      headers: {
        if (Session.token != null)
          'Authorization': 'Bearer ${Session.token}',
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Error descargando PDF");
    }

    final file =
        File('/storage/emulated/0/Download/ticket_$idTicket.pdf');

    await file.writeAsBytes(res.bodyBytes);

    return file;
  }
}
