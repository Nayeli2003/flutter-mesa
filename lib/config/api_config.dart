class ApiConfig {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  static const String baseStorage = 'http://127.0.0.1:8000';

  // ========================
  // ENDPOINTS FIJOS
  // ========================
  static String login = "$baseUrl/login";
  static String tickets = "$baseUrl/tickets";
  static String usuarios = "$baseUrl/usuarios";
  static String tipoProblema = "$baseUrl/tipo-problema";
  static String tareas = "$baseUrl/tareas";
  static String misTareas = "$baseUrl/mis-tareas";
  static String tecnicos = "$baseUrl/tecnicos";

  // ========================
  // ENDPOINTS DINÁMICOS
  // ========================
  static String ticketMensajes(int id) => "$baseUrl/tickets/$id/mensajes";
  static String archivo(String path) => "$baseStorage/archivo/$path";

  static String finalizarTarea(int id) => "$tareas/$id/finalizar";
  static String memoriaTarea(int id) => "$tareas/$id/memoria";
  static String reabrirTarea(int id) => "$tareas/$id/reabrir";
  static String updateTarea(int id) => "$tareas/$id";

  static String tipoProblemaById(int id) => "$tipoProblema/$id";
  static String toggleProblema(int id) => "$tipoProblema/$id/toggle";
  static String sucursales = "$baseUrl/sucursales";
}
