import 'dart:convert';
import 'package:http/http.dart' as http;
import 'session.dart';

class ChatApi {
  final String baseUrl;

  ChatApi({required this.baseUrl});

  Future<List<dynamic>> getMensajes(int idTicket) async {
    final res = await http.get(
      Uri.parse('$baseUrl/tickets/$idTicket/mensajes'),
      headers: {
        'Authorization': 'Bearer ${Session.token}',
        'Accept': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Error al cargar mensajes");
    }

    return jsonDecode(res.body);
  }

  Future<void> enviarMensaje(int idTicket, String mensaje) async {
    final res = await http.post(
      Uri.parse('$baseUrl/tickets/$idTicket/mensajes'),
      headers: {
        'Authorization': 'Bearer ${Session.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "mensaje": mensaje,
      }),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("Error al enviar mensaje");
    }
  }
}