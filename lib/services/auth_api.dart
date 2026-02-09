import 'dart:convert';
import 'package:http/http.dart' as http;
import 'session.dart';

class AuthApi {
  final String baseUrl; // http://127.0.0.1:8000/api
  AuthApi({required this.baseUrl});

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/login');

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (res.statusCode != 200) {
      throw Exception('Login falló: ${res.statusCode} ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;

  
    final token = data['token']?.toString();

    if (token == null || token.isEmpty) {
      throw Exception('No llegó token en la respuesta: ${res.body}');
    }

    Session.token = token; //  guardado
  }

  void logout() {
    Session.token = null;
  }
}
