import 'package:flutter/material.dart';

// el importar las vistas
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


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mesa de Ayuda',

      // estilos de colores para sana sana
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

      // Rutas de las paginas
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginView(), //inicio de sesion
        '/admin': (context) =>
            const AdminDashboardView(), //vista de administrador
        '/technician': (context) =>
            const TechnicianDashboardView(), //vista de tecnico
        '/branch': (context) => const BranchHomeView(), //vista de sucursal
        '/create-ticket': (context) =>
            const CreateTicketView(), //vista de creacion de ticket
        '/ticket-detail': (context) =>
            const TicketDetailView(), //vista de ticket detalles
        '/help': (context) =>
            const HelpView(), //vista de ayuda por parte de sucursal
        '/tech-inprogress': (_) => const TechnicianTicketsView(
          title: 'En proceso',
          statusFilter: TicketStatus.enProceso,
        ),
        '/tech-closed': (_) => const TechnicianTicketsView(
          title: 'Cerrados',
          statusFilter: TicketStatus.cerrado,
        ),
        '/admin-tickets': (_) => const AdminTicketsView(),//Tickets de administrador
        '/admin-users': (_) => const AdminUsersView(),// vista de usuarios
        '/admin-metrics': (_) => const AdminMetricsView(),//Vista de metricas


      },
    );
  }
}
