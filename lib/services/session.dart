class Session {
  static String? token;
  static int? idUsuario;
  static int? idRol;
  static int? idSucursal;
  static String? username;
  static String? nombre;

  static void clear() {
    token = null;
    idUsuario = null;
    idRol = null;
    idSucursal = null;
    username = null;
    nombre = null;
  }

  static bool get isLoggedIn => token != null && token!.isNotEmpty;
}
