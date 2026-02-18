import 'dart:convert';
import 'package:http/http.dart' as http;
import 'session.dart';

class AuthApi {
  final String baseUrl;

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
        "username": username,
        "password": password,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception("Credenciales incorrectas");
    }

    final data = jsonDecode(res.body);

    // GUARDAMOS EN SESSION
    Session.token = data["token"];
    Session.idUsuario = data["user"]["id_usuario"];
    Session.nombre = data["user"]["nombre"];

    // Si tu backend devuelve rol como string
    final rol = data["user"]["rol"];

    if (rol == "admin") {
      Session.idRol = 1;
    } else if (rol == "tecnico") {
      Session.idRol = 2;
    } else {
      Session.idRol = 3;//Aqui cae la sucursal 
    }

    await Session.save();
  }

  Future<void> logout() async {
    await Session.clear();
  }
}
