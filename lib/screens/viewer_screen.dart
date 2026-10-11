import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../services/signaling_service.dart';
import '../services/webrtc_service.dart';
import '../theme.dart';

class ViewerScreen extends StatefulWidget {
  const ViewerScreen({super.key});

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final SignalingService _signaling = SignalingService();
  final TransformationController _zoom = TransformationController();
  late final WebRTCService _webrtc;

  bool _isScanning = true;
  bool _hasVideo = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _remoteRenderer.initialize();
    _webrtc = WebRTCService(_signaling);
    _webrtc.onRemoteStream = (stream) {
      if (!mounted) return;
      setState(() {
        _remoteRenderer.srcObject = stream;
        _hasVideo = true;
      });
    };
    _signaling.onClosed = () {
      if (mounted) setState(() => _error = 'Connessione persa');
    };
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _zoom.dispose();
    _remoteRenderer.dispose();
    _webrtc.dispose();
    _signaling.stop();
    super.dispose();
  }

  Future<void> _onQrScanned(BarcodeCapture capture) async {
    if (!_isScanning) return;
    final raw = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    if (raw == null || !raw.startsWith('ws://')) return;

    setState(() => _isScanning = false);
    try {
      await _webrtc.initConnection();
      await _signaling.connectTo(raw); // attende l'apertura del socket
      await _webrtc.createOffer();
    } catch (e) {
      debugPrint('Connessione fallita: $e');
      if (mounted) {
        setState(() {
          _error = 'Impossibile collegarsi al trasmettitore';
          _isScanning = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(_hasVideo ? '' : 'Ricevitore'),
        actions: [
          if (_hasVideo)
            IconButton(
              tooltip: 'Reimposta zoom',
              icon: const Icon(Icons.zoom_out_map_rounded),
              onPressed: () => _zoom.value = Matrix4.identity(),
            ),
        ],
      ),
      body: _isScanning ? _buildScanner() : _buildVideo(),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(onDetect: _onQrScanned),
        Center(
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.redBright, width: 3),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0, 0.8),
          child: Text(_error ?? 'Inquadra il QR del trasmettitore',
              style: TextStyle(
                  color: _error == null ? Colors.white : AppColors.highlight,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  /// Video con pinch-to-zoom (fino a 8x), trascinamento e doppio tap per reimpostare.
  Widget _buildVideo() {
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onDoubleTap: () => _zoom.value = Matrix4.identity(),
          child: InteractiveViewer(
            transformationController: _zoom,
            minScale: 1,
            maxScale: 8,
            child: RTCVideoView(
              _remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
            ),
          ),
        ),
        if (!_hasVideo || _error != null)
          IgnorePointer(
            child: Center(
              child: Text(_error ?? 'Connessione in corso…',
                  style: TextStyle(
                      color: _error == null ? AppColors.steel : AppColors.highlight,
                      fontSize: 16)),
            ),
          ),
      ],
    );
  }
}
