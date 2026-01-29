import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  final _storage = const FlutterSecureStorage();

  bool _loading = false;
  String? _error;

  bool _showPassword = false; //

  // Para Android emulator usa 10.0.2.2
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://127.0.0.1:8000/api',
    headers: {'Accept': 'application/json'},
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  String _extractRol(dynamic user) {
    // Soporta varias formas:
    // 1) user['rol'] = 'admin'
    // 2) user['rol'] = { nombre_rol: 'admin' }
    // 3) user['nombre_rol'] = 'admin'
    final rolField = (user is Map<String, dynamic>) ? user['rol'] : null;

    if (rolField is String) return rolField.toLowerCase().trim();

    if (rolField is Map) {
      final nombre = rolField['nombre_rol']?.toString() ?? '';
      return nombre.toLowerCase().trim();
    }

    final nombreRol = (user is Map<String, dynamic>)
        ? (user['nombre_rol']?.toString() ?? '')
        : '';

    return nombreRol.toLowerCase().trim();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final username = _userController.text.trim();
    final password = _passController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Ingresa usuario y contraseña';
      });
      return;
    }

    try {
      final res = await _dio.post('/login', data: {
        'username': username,
        'password': password,
      });

      final token = res.data['token']?.toString();
      final user = res.data['user'];

      if (token == null || token.isEmpty) {
        setState(() => _error = 'No se recibió token del servidor');
        return;
      }
      if (user is! Map<String, dynamic>) {
        setState(() => _error = 'Respuesta inválida del servidor (user)');
        return;
      }

      final rol = _extractRol(user);

      //  Guarda token y datos básicos
      await _storage.write(key: 'token', value: token);
      await _storage.write(key: 'rol', value: rol);

      final idUsuario = user['id_usuario']?.toString();
      if (idUsuario != null) {
        await _storage.write(key: 'id_usuario', value: idUsuario);
      }

      final idSucursal = user['id_sucursal']?.toString();
      if (idSucursal != null) {
        await _storage.write(key: 'id_sucursal', value: idSucursal);
      }

      //  (Recomendado) setear token en Dio para siguientes requests
      _dio.options.headers['Authorization'] = 'Bearer $token';

      if (!mounted) return;

      //  Navegación por rol
      if (rol == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else if (rol == 'tecnico') {
        Navigator.pushReplacementNamed(context, '/technician');
      } else if (rol == 'sucursal') {
        Navigator.pushReplacementNamed(context, '/branch');
      } else {
        setState(() => _error = 'Rol desconocido: $rol');
      }
    } on DioException catch (e) {
      // Mensaje de error más confiable
      String msg = 'Error al iniciar sesión';
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        msg = data['message']?.toString() ?? msg;
      } else if (e.response?.statusCode == 401) {
        msg = 'Usuario o contraseña incorrectos';
      }

      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 243, 244, 243),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(25),
            width: 320,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/logo.png', height: 120),
                const SizedBox(height: 20),

                const Text(
                  'Iniciar sesión',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),

                const SizedBox(height: 25),

                TextField(
                  controller: _userController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Usuario',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: _passController,
                  obscureText: !_showPassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _loading ? null : _login(),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    //  ojito
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                      icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),

                const SizedBox(height: 13),

                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Entrar',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color.fromARGB(255, 238, 241, 238),
                            ),
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
}
