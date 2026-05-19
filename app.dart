/**
*Student Number: 218009030, 220049798, 220033640, 222057332, 221002961.
*Student Name: TA RASEGO, LONWABO SIFUMBA, BN NGALO, TC LAAT, TC RADEBE.
*Question: 
*/



import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sa_apply/core/constants/app_routes.dart';
import 'package:sa_apply/core/theme/app_theme.dart';
import 'package:sa_apply/models/application_model.dart';
import 'package:sa_apply/providers/auth_provider.dart';
import 'package:sa_apply/providers/application_provider.dart';
import 'package:sa_apply/views/auth/login_screen.dart';
import 'package:sa_apply/views/auth/signup_screen.dart';
import 'package:sa_apply/views/student/home_screen.dart';
import 'package:sa_apply/views/student/application_form_screen.dart';
import 'package:sa_apply/views/student/application_detail_screen.dart';
import 'package:sa_apply/views/admin/admin_dashboard_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ApplicationProvider()),
      ],
      child: MaterialApp(
        title: 'StudAssist',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: AppRoutes.login,
        routes: {
          AppRoutes.login: (_) => const LoginScreen(),
          AppRoutes.signup: (_) => const SignupScreen(),
          AppRoutes.studentHome: (_) => const StudentHomeScreen(),
          AppRoutes.applicationForm: (_) => const ApplicationFormScreen(),
          AppRoutes.adminDashboard: (_) => const AdminDashboardScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.applicationDetail) {
            final app = settings.arguments as ApplicationModel;
            return MaterialPageRoute(
              builder: (_) => ApplicationDetailScreen(application: app),
            );
          }
          return null;
        },
      ),
    );
  }
}
