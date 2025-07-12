import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

class MyApp extends StatelessWidget {
@override
Widget build(BuildContext context) {
  return MaterialApp(
    title: 'Registro de Ponto',
    theme: ThemeData(
      primarySwatch: Colors.blue,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
    localizationsDelegates: [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: [
      const Locale('pt', 'BR'),
      const Locale('en', 'US'),
    ],
    locale: const Locale('pt', 'BR'),
    home: Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return authProvider.isAuthenticated ? HomeScreen() : LoginScreen();
      },
    ),
  );
}
}
