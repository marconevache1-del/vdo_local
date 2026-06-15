import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/signaling_service.dart';
import '../services/webrtc_service.dart'; // NUOVO IMPORT

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final SignalingService _signaling = SignalingService();
  late WebRTCService _webrtc; // LA NOSTRA CENTRALINA WEBRTC
  
  String? _qrData;

  @override
  void initState() {
    super.initState();
    // Colleghiamo la centralina al walkie-talkie
    _webrtc = WebRTCService(_signaling); 
    _initCameraAndServer();
  }

  Future<void> _initCameraAndServer() async {
    await _localRenderer.initialize();
    
    // Inizializziamo il tubo di rete
    await _webrtc.initConnection();

    final mediaConstraints = <String, dynamic>{
      'audio': false,
      'video': {
        'facingMode': 'environment',
        'width': {'ideal': 1920},
        'height': {'ideal': 1080},
      }
    };

    try {
      MediaStream stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      setState(() {
        _localRenderer.srcObject = stream;
      });
      // INIETTIAMO IL FLUSSO VIDEO DELLA FOTOCAMERA NEL TUBO
      await _webrtc.addLocalStream(stream);
    } catch (e) {
      print("Errore fotocamera: $e");
    }

    String? uri = await _signaling.startLocalServer();
    if (uri != null) {
      setState(() {
        _qrData = uri;
      });
    }
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _webrtc.dispose(); // SPEGNIAMO WEBRTC
    _signaling.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Trasmettitore'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: RTCVideoView(
              _localRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),
          if (_qrData != null)
            Positioned(
              bottom: 30,
              right: 30,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)]
                ),
                child: Column(
                  children: [
                    QrImageView(data: _qrData!, version: QrVersions.auto, size: 150.0),
                    const SizedBox(height: 8),
                    const Text("Scansiona per ricevere", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}