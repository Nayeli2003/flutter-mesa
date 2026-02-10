import 'package:flutter/material.dart';
import 'services/session.dart'; 
// vistas
import 'views/login_view.dart';
import 'views/admin/admin_dashboard_view.dart';
import 'views/technician/technician_dashboard_view.dart';
import 'views/branch/branch_home_view.dart';
import 'views/ticket/create_ticket_view.dart';
import 'views/ticket/ticket_detail_view.dart';
import 'views/help/help_view.dart';
import 'views/technician/technician_tickets_view.dart';
import 'views/admin/admin_tickets_view.dart';
import 'views/admin/admin_users_view.dart';
import 'views/admin/admin_metrics_view.dart';

void main() async {
  // necesario para usar await antes de runApp
  WidgetsFlutterBinding.ensureInitialized();

  //carga token guardado (web/desktop)
  await Session.load();

  runApp(const MyApp());
}

///Widget que protege rutas: si no hay token → manda a login
class GuardedRoute extends StatelessWidget {
  final Widget child;
  const GuardedRoute({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // si NO hay token, manda a login
    if (Session.token == null) {
      // pushReplacement después del build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });

      // mientras redirige, muestra loader
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // si hay token, deja pasar
    return child;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mesa de Ayuda',

      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF3F4F3),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          primary: const Color(0xFF4CAF50),
          secondary: const Color(0xFFA5D6A7),
          error: const Color(0xFFEF4444),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1F2937),
          elevation: 0,
          centerTitle: true,
        ),
      ),

      initialRoute: '/login',

      routes: {
        '/login': (context) => const LoginView(),

        // protegemos todas las rutas que requieren sesión
        '/admin': (context) => const GuardedRoute(child: AdminDashboardView()),
        '/technician': (context) =>
            const GuardedRoute(child: TechnicianDashboardView()),
        '/branch': (context) => const GuardedRoute(child: BranchHomeView()),
        '/create-ticket': (context) =>
            const GuardedRoute(child: CreateTicketView()),
        '/ticket-detail': (context) =>
            const GuardedRoute(child: TicketDetailView()),
        '/help': (context) => const GuardedRoute(child: HelpView()),

        '/tech-inprogress': (_) => const GuardedRoute(
              child: TechnicianTicketsView(
                title: 'En proceso',
                statusFilter: TicketStatus.enProceso,
              ),
            ),
        '/tech-closed': (_) => const GuardedRoute(
              child: TechnicianTicketsView(
                title: 'Cerrados',
                statusFilter: TicketStatus.cerrado,
              ),
            ),

        '/admin-tickets': (_) =>
            const GuardedRoute(child: AdminTicketsView()),//vista ded tickets
        '/admin-users': (_) => const GuardedRoute(child: AdminUsersView()),//vista de administrador de usuarios
        '/admin-metrics': (_) =>
            const GuardedRoute(child: AdminMetricsView()),//metricas que puede ver el administrador
      },
    );
  }
}
