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

  //  Cambia esta URL según dónde corras la app:
  // Android emulator: http://10.0.2.2:8000
  // iOS simulator: http://127.0.0.1:8000
  // Cel físico: http://IP_DE_TU_PC:8000
  //Android emulador: 'http://10.0.2.2:8000/api',
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://127.0.0.1:8000/api',
    headers: {'Accept': 'application/json'},
  ));

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _dio.post('/login', data: {
        'username': _userController.text.trim(),
        'password': _passController.text,
      });

      final token = res.data['token'] as String;
      final user = res.data['user'] as Map<String, dynamic>;

      // Tu backend manda: rol = admin / tecnico / sucursal
      final rol = (user['rol'] ?? '').toString().toLowerCase();

      //  Guarda token y datos básicos
      await _storage.write(key: 'token', value: token);
      await _storage.write(key: 'rol', value: rol);
      await _storage.write(key: 'id_usuario', value: user['id_usuario'].toString());
      if (user['id_sucursal'] != null) {
        await _storage.write(key: 'id_sucursal', value: user['id_sucursal'].toString());
      }

      if (!mounted) return;

      // Navegación por rol
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
      final msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString() ?? 'Error al iniciar sesión')
          : 'Error al iniciar sesión';

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
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock),
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
