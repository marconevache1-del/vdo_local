import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'viewer_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold è l'impalcatura standard di una schermata (fornisce lo sfondo, la barra in alto, ecc.)
    return Scaffold(
      appBar: AppBar(
        title: const Text('VDO Local'),
        centerTitle: true,
      ),
      // Padding aggiunge spazio attorno ai bordi
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        // Column mette gli elementi in colonna (uno sotto l'altro)
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Centra tutto verticalmente
          crossAxisAlignment: CrossAxisAlignment.stretch, // Allarga i bottoni per tutta la larghezza
          children: [
            
            // --- BOTTONE TRASMETTI ---
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt, size: 32),
              label: const Text('TRASMETTI', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 32),
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16), // Bordi arrotondati
                ),
              ),
              onPressed: () {
                // Navigator è il "regista" che gestisce il cambio schermata
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CameraScreen()),
                );
              },
            ),
            
            const SizedBox(height: 32), // Spazio vuoto tra i due bottoni
            
            // --- BOTTONE RICEVI ---
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner, size: 32),
              label: const Text('RICEVI', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 32),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ViewerScreen()),
                );
              },
            ),
            
          ],
        ),
      ),
    );
  }
}