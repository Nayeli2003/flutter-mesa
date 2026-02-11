import 'dart:convert';
import 'package:http/http.dart' as http;
import 'session.dart';

class UsersApi {
  final String baseUrl; // ejemplo: http://127.0.0.1:8000/api

  UsersApi({required this.baseUrl});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (Session.token != null) 'Authorization': 'Bearer ${Session.token}',
  };

  // LISTAR USUARIOS
  Future<List<dynamic>> list({int? idRol, bool? activo, String? q}) async {
    final params = <String, String>{};

    if (idRol != null) params['id_rol'] = '$idRol';
    if (activo != null) params['activo'] = activo ? '1' : '0';
    if (q != null && q.trim().isNotEmpty) params['q'] = q.trim();

    final uri = Uri.parse('$baseUrl/usuarios').replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers);

    if (res.statusCode != 200) {
      throw Exception('Error al listar: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as List<dynamic>;
  }

  // CREAR ADMIN
  Future<void> crearAdmin({
    required String nombre,
    required String username,
    required String password,
    required bool activo,
  }) async {
    final uri = Uri.parse('$baseUrl/usuarios/admin');
    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'nombre': nombre,
        'username': username,
        'password': password,
        'activo': activo,
      }),
    );
    if (res.statusCode != 201) throw Exception(res.body);
  }

  // CREAR TÉCNICO
  Future<void> crearTecnico({
    required String nombre,
    required String username,
    required String password,
    required bool activo,
  }) async {
    final uri = Uri.parse('$baseUrl/usuarios/tecnico');
    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'nombre': nombre,
        'username': username,
        'password': password,
        'activo': activo,
      }),
    );
    if (res.statusCode != 201) throw Exception(res.body);
  }

  // CREAR SUCURSAL
  Future<void> crearSucursal({
    required int idSucursal,
    required String nombreSucursal,
    required String username,
    required String password,
    required bool activo,
  }) async {
    final uri = Uri.parse('$baseUrl/usuarios/sucursal');
    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'id_sucursal': idSucursal,
        'nombre': nombreSucursal,
        'username': username,
        'password': password,
        'activo': activo,
      }),
    );
    if (res.statusCode != 201) throw Exception(res.body);
  }

  // ACTIVAR / DESACTIVAR
  Future<void> toggleEstado(int idUsuario) async {
    final uri = Uri.parse('$baseUrl/usuarios/$idUsuario/estado');
    final res = await http.patch(uri, headers: _headers);
    if (res.statusCode != 200) throw Exception(res.body);
  }

  // ELIMINAR
  Future<void> eliminar(int idUsuario) async {
    final uri = Uri.parse('$baseUrl/usuarios/$idUsuario');
    final res = await http.delete(uri, headers: _headers);
    if (res.statusCode != 200) throw Exception(res.body);
  }

  // EDITAR USUARIO (PUT)
  Future<void> updateUser({
    required int idUsuario,
    String? nombre,
    String? username,
    int? idRol,
    int? idSucursal,
    bool? activo,
    String? password,
  }) async {
    final uri = Uri.parse('$baseUrl/usuarios/$idUsuario');

    final res = await http.put(
      uri,
      headers: _headers,
      body: jsonEncode({
        if (nombre != null) "nombre": nombre,
        if (username != null) "username": username,
        if (idRol != null) "id_rol": idRol,
        if (idSucursal != null) "id_sucursal": idSucursal,
        if (activo != null) "activo": activo,
        if (password != null && password.isNotEmpty) "password": password,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Error al actualizar: ${res.statusCode} ${res.body}');
    }
  }
}
