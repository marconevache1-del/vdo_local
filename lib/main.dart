import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  // Assicura che l'engine di Flutter sia pronto prima di avviare l'app
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VdoLocalApp());
}

class VdoLocalApp extends StatelessWidget {
  const VdoLocalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VDO Local',
      // Impostiamo un tema scuro di base, molto elegante e standard per le app video
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark, 
        ),
        useMaterial3: true,
      ),
      // La prima schermata che si apre
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false, // Rimuove il banner "DEBUG" in alto a destra
    );
  }
}