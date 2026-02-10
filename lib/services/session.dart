import 'package:shared_preferences/shared_preferences.dart';

class Session {
  static String? token;
  static int? idUsuario;
  static int? idRol;
  static int? idSucursal;
  static String? username;
  static String? nombre;

  // guardar (llámalo después de login)
  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token ?? '');

    await prefs.setInt('idUsuario', idUsuario ?? 0);
    await prefs.setInt('idRol', idRol ?? 0);
    await prefs.setInt('idSucursal', idSucursal ?? 0);

    await prefs.setString('username', username ?? '');
    await prefs.setString('nombre', nombre ?? '');
  }

  // cargar (se usa en main() antes de runApp)
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final t = prefs.getString('token');
    token = (t != null && t.isNotEmpty) ? t : null;

    final iu = prefs.getInt('idUsuario');
    idUsuario = (iu != null && iu != 0) ? iu : null;

    final ir = prefs.getInt('idRol');
    idRol = (ir != null && ir != 0) ? ir : null;

    final isuc = prefs.getInt('idSucursal');
    idSucursal = (isuc != null && isuc != 0) ? isuc : null;

    final u = prefs.getString('username');
    username = (u != null && u.isNotEmpty) ? u : null;

    final n = prefs.getString('nombre');
    nombre = (n != null && n.isNotEmpty) ? n : null;
  }

  // limpiar (logout)
  static Future<void> clear() async {
    token = null;
    idUsuario = null;
    idRol = null;
    idSucursal = null;
    username = null;
    nombre = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('idUsuario');
    await prefs.remove('idRol');
    await prefs.remove('idSucursal');
    await prefs.remove('username');
    await prefs.remove('nombre');
  }
}
