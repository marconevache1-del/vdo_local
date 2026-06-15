import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/signaling_service.dart';
import '../services/webrtc_service.dart';

class ViewerScreen extends StatefulWidget {
  const ViewerScreen({super.key});

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final SignalingService _signaling = SignalingService();
  late WebRTCService _webrtc;
  
  bool _isScanning = true; // Finché è true, mostriamo la fotocamera per il QR

  @override
  void initState() {
    super.initState();
    _remoteRenderer.initialize();
    _webrtc = WebRTCService(_signaling);
    
    // Quando il tubo consegna il video dall'altro telefono, mostralo!
    _webrtc.onRemoteStream = (stream) {
      setState(() {
        _remoteRenderer.srcObject = stream;
      });
    };
  }

  @override
  void dispose() {
    _remoteRenderer.dispose();
    _webrtc.dispose();
    _signaling.stop();
    super.dispose();
  }

  // Cosa succede quando la fotocamera legge un QR
  void _onQrScanned(BarcodeCapture capture) async {
    if (!_isScanning) return; // Evita di connettersi 100 volte in un secondo
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      String uri = barcodes.first.rawValue!;
      
      // Controlliamo che sia il nostro codice (inizia con ws://)
      if (uri.startsWith('ws://')) {
        print(">>> QR SCANSIONATO CORRETTAMENTE. URI: $uri");
        setState(() {
          _isScanning = false; // Spegni lo scanner
        });
        
        // 1. Connettiti al walkie talkie del Trasmettitore
        _signaling.connectTo(uri);
        print(">>> TENTATIVO DI CONNESSIONE AL WEBSOCKET...");
        
        // 2. Prepara il tubo
        await _webrtc.initConnection();
        
        // 3. Aspetta mezzo secondo che la radio si sintonizzi e fai tu l'offerta!
        await Future.delayed(const Duration(milliseconds: 2000));

        print(">>> INVIO DELL'OFFERTA AL TRASMETTITORE...");
        await _webrtc.createOffer();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Ricevitore'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      // Se stiamo scansionando mostriamo lo scanner, altrimenti mostriamo il video in arrivo
      body: _isScanning 
        ? MobileScanner(
            onDetect: _onQrScanned,
          )
        : RTCVideoView(
            _remoteRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
    );
  }
}