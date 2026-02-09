
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mesa_sana/services/session.dart';

class AuthApi {
  final String baseUrl; // ejemplo: http://127.0.0.1:8000/api

  AuthApi({required this.baseUrl});

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/login');

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Login falló: ${res.statusCode} ${res.body}');
    }

    final data = jsonDecode(res.body);

    // ✅ Ajusta estos keys a lo que mande tu backend
    // Normalmente: { token: "...", user: {...} }
    final token = data['token']?.toString();
    if (token == null || token.isEmpty) {
      throw Exception('El backend no devolvió token. Respuesta: ${res.body}');
    }

    Session.token = token;

    // si tu backend manda user
    final user = data['user'];
    if (user != null) {
      Session.idUsuario = user['id_usuario'] ?? user['id'] ;
      Session.idRol = user['id_rol'];
      Session.idSucursal = user['id_sucursal'];
      Session.username = user['username']?.toString();
      Session.nombre = user['nombre']?.toString();
    }
  }

  Future<void> logout() async {
    if (Session.token == null) return;

    final uri = Uri.parse('$baseUrl/logout');
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Session.token}',
      },
    );

    // aunque falle, limpiamos sesión
    Session.clear();

    if (res.statusCode != 200) {
      throw Exception('Logout falló: ${res.statusCode} ${res.body}');
    }
  }
}
